package Skilletor::Source::Url;
# ABSTRACT: A url source: an https .tar.gz, conditional GET, staged swap into the shared cache

use Moo;
use Digest::SHA qw( sha256_hex );
use Fcntl ();
use HTTP::Tiny;
use Path::Tiny qw( path );
use Scalar::Util qw( blessed );
use Skilletor::Cache qw( url_cache_dir );
use Skilletor::Error::Source;
use Skilletor::Error::Tar;
use Skilletor::FSUtil qw( encode_text path_join path_resolve read_text );
use Skilletor::Gzip qw( gunzip_sync inflate_sync );
use Skilletor::Tar qw( parse_tar strip_top_level is_reserved VERSION_FILE );
use Skilletor::URL qw( parse_url );
use namespace::clean;

with 'Skilletor::Role::Source';

our $VERSION = '0.001';

# The first line of a version file: the format of its tree. 2: an entry's owner executable bit
# is kept.
use constant CACHE_FORMAT => 'format 2';

# A stage or backup tree the publication makes next to a cache dir.
my $LEFTOVER = qr/\A([0-9a-f]{16})\.(stage|backup)-[A-Za-z0-9]{6}\z/;
my @TEMP_CHARS = ( 'a' .. 'z', 'A' .. 'Z', 0 .. 9 );

has url => (
  is       => 'ro',
  required => 1,
);

has cache_root => (
  is       => 'ro',
  required => 1,
);

has timeout_ms => (
  is      => 'ro',
  default => sub { 60_000 },
);

# Tests only: permit http://127.0.0.1 and http://localhost.
has allow_http => (
  is      => 'ro',
  default => sub { 0 },
);

has http => (
  is => 'lazy',
);

sub _build_http {
  my ( $self ) = @_;
  return HTTP::Tiny->new(
    agent        => 'node',
    timeout      => $self->timeout_ms / 1000,
    verify_SSL   => 1,
    max_redirect => 20,
  );
}

sub cache_dir {
  my ( $self ) = @_;
  return url_cache_dir( $self->cache_root, $self->url );
}

sub _assert_scheme {
  my ( $self ) = @_;
  my $u = parse_url( $self->url ) or Skilletor::Error::Source->throw('Invalid URL');
  return if $u->{protocol} eq 'https:';
  my $local_http = $u->{protocol} eq 'http:' && ( $u->{hostname} eq '127.0.0.1' || $u->{hostname} eq 'localhost' );
  return if $self->allow_http && $local_http;
  Skilletor::Error::Source->throw( 'url source must be https://: '.$self->url );
}

sub _fail { Skilletor::Error::Source->throw( $_[1] ) }

# A request with the headers Node's fetch sends, the body decoded as fetch decodes it.
sub _request {
  my ( $self, $method, $headers ) = @_;
  my %h = (
    accept            => '*/*',
    'accept-language' => '*',
    'sec-fetch-mode'  => 'cors',
    'accept-encoding' => 'gzip, deflate',
    %$headers,
  );
  if ( exists $headers->{'If-None-Match'} ) {
    $h{pragma}          = 'no-cache';
    $h{'cache-control'} = 'no-cache';
  }
  my $res = $self->http->request( $method, $self->url, { headers => \%h } );
  if ( $res->{status} == 599 ) {
    $self->_fail( ( $res->{content} // '' ) =~ /timed? ?out/i ? 'This operation was aborted' : 'fetch failed' );
  }
  my $encoding = lc( _header( $res, 'content-encoding' ) // '' );
  if ( $method eq 'GET' && length( $res->{content} // '' ) && $encoding =~ /\A(?:x-)?(gzip|deflate)\z/ ) {
    $res->{content} = $1 eq 'gzip' ? gunzip_sync( $res->{content} ) : inflate_sync( $res->{content} );
  }
  return $res;
}

sub _header {
  my ( $res, $name ) = @_;
  my $v = $res->{headers}{$name};
  return undef unless defined $v;
  return ref $v eq 'ARRAY' ? join( ', ', @$v ) : $v;
}

sub _msg { my ( $err ) = @_; return blessed $err && $err->can('message') ? $err->message : "$err" =~ s/ at \S+ line \d+\.?\n?\z//r }

sub resolve {
  my ( $self ) = @_;
  $self->_assert_scheme;
  my $dir = $self->cache_dir;
  my $result = eval {
    my $cached = $self->cache_version($dir);
    my $etag = ( defined $cached && $cached =~ /\Aetag:(.*)\z/s ) ? $1 : undef;
    my $res = $self->_request( GET => defined $etag ? { 'If-None-Match' => $etag } : {} );
    return +{ dir => $dir, version => $cached } if $res->{status} == 304 && defined $etag;
    $self->_fail( 'HTTP '.$res->{status} ) unless $res->{status} >= 200 && $res->{status} <= 299;
    my $body     = $res->{content} // '';
    my $res_etag = _header( $res, 'etag' );
    my $version  = ( defined $res_etag && length $res_etag ) ? 'etag:'.$res_etag : 'sha256:'.sha256_hex($body);
    my @entries  = grep { !is_reserved( $_->{name} ) } @{ strip_top_level( parse_tar( gunzip_sync($body) ) ) };
    my $warning  = $self->_publish( $dir, \@entries, $version );
    +{ dir => $dir, version => $version, ( defined $warning ? ( warning => $warning ) : () ) };
  };
  return $result if $result;
  my $err = $@;
  if ( blessed $err && $err->isa('Skilletor::Error::Tar') ) {
    Skilletor::Error::Source->throw( 'url source '.$self->url.' failed: '.$err->message );
  }
  if ( -e $dir ) {
    return {
      dir     => $dir,
      version => $self->cache_version($dir) // 'unknown',
      warning => 'download failed for '.$self->url.', using cache ('._msg($err).')',
    };
  }
  Skilletor::Error::Source->throw( 'url source '.$self->url.' failed: '._msg($err) );
}

# The cache as it is, without a request: what resolve serves when a download fails, without
# the warning.
sub cached {
  my ( $self ) = @_;
  $self->_assert_scheme;
  my $dir = $self->cache_dir;
  Skilletor::Error::Source->throw( 'url source '.$self->url.' is not in the cache (no fetch)' ) unless -e $dir;
  return { dir => $dir, version => $self->cache_version($dir) // 'unknown' };
}

sub check {
  my ( $self, $cached_version ) = @_;
  $self->_assert_scheme;
  my $res  = $self->_request( HEAD => {} );
  my $etag = _header( $res, 'etag' );
  return 1 unless defined $etag && length $etag && defined $cached_version && $cached_version =~ /\Aetag:/;
  return $etag ne substr( $cached_version, 5 ) ? 1 : 0;
}

# The version of the tree in a cache dir; undef without a readable, well-formed one of the
# current format.
sub cache_version {
  my ( $self, $dir ) = @_;
  my $text = eval { read_text( path_join( $dir, VERSION_FILE ) ) };
  return undef unless defined $text;
  my ( $format, $version, @rest ) = split /\n/, $text, -1;
  return undef if !defined $format || $format ne CACHE_FORMAT || @rest;
  return ( defined $version && $version =~ /\A(?:etag|sha256):[^\r\n]+\z/ ) ? $version : undef;
}

sub _mkdtemp {
  my ( $self, $prefix ) = @_;
  for ( 1 .. 100 ) {
    my $path = $prefix.join '', map { $TEMP_CHARS[ int rand @TEMP_CHARS ] } 1 .. 6;
    return $path if mkdir $path, 0700;
    die 'mkdtemp '.$prefix.': '.$! unless $!{EEXIST};
  }
  die 'mkdtemp '.$prefix.': no free name';
}

sub _write_entries {
  my ( $self, $dir, $entries ) = @_;
  my $root = path_resolve($dir);
  for my $e (@$entries) {
    my $dest = path_resolve( path_join( $dir, $e->{name} ) );
    if ( $dest ne $root && index( $dest, $root.'/' ) != 0 ) {
      Skilletor::Error::Tar->throw( 'unsafe tar entry (escapes target): '.$e->{name} );
    }
    my $bytes_dest = encode_text($dest);
    if ( $e->{type} eq 'dir' ) {
      path($bytes_dest)->mkpath;
      next;
    }
    path($bytes_dest)->parent->mkpath;
    sysopen( my $fh, $bytes_dest, Fcntl::O_WRONLY() | Fcntl::O_CREAT() | Fcntl::O_TRUNC(), $e->{executable} ? 0777 : 0666 )
      or die 'open '.$dest.': '.$!."\n";
    binmode $fh;
    print {$fh} $e->{data};
    close $fh or die 'close '.$dest.': '.$!."\n";
  }
}

# Extract completely, with the tree's version inside it, before replacing the cache; every
# rename moves tree and version together. Returns the cleanup warning, if any.
sub _publish {
  my ( $self, $dir, $entries, $version ) = @_;
  path($dir)->parent->mkpath;
  my $staging = $self->_mkdtemp( $dir.'.stage-' );
  my ( $backup, $old_moved, $published ) = ( undef, 0, 0 );
  my @cleanup_warnings;
  my $ok = eval {
    $self->_write_entries( $staging, $entries );
    path( $staging, VERSION_FILE )->spew_raw( encode_text( CACHE_FORMAT."\n".$version ) );
    if ( -e $dir ) {
      # A rename cannot replace a nonempty directory.
      $backup = $self->_mkdtemp( $dir.'.backup-' );
      rename $dir, path_join( $backup, 'tree' ) or die 'rename '.$dir.': '.$!."\n";
      $old_moved = 1;
    }
    unless ( rename $staging, $dir ) {
      my $err = $!;
      if ($old_moved) {
        if ( rename path_join( $backup, 'tree' ), $dir ) {
          $old_moved = 0;
        }
        else {
          die 'cache publication failed ('.$err.'); restoration failed ('.$!.'); last good cache remains at '
            .path_join( $backup, 'tree' )."\n";
        }
      }
      die 'rename '.$staging.': '.$err."\n";
    }
    # Commit point: cleanup must not turn new bytes into an old-version fallback.
    $published = 1;
    1;
  };
  my $err = $@;
  # Keep the backup when restoration failed; the sweep puts it back.
  my @obsolete = ( $staging, ( $backup && ( !$old_moved || $published ) ? ($backup) : () ) );
  for my $p (@obsolete) {
    next unless -e $p;
    my $removed = eval { path($p)->remove_tree( { safe => 0 } ); 1 };
    push @cleanup_warnings, 'cache cleanup failed for '.$p.' ('._msg($@).')' unless $removed && !-e $p;
  }
  die $err unless $ok;
  return @cleanup_warnings ? join( '; ', @cleanup_warnings ) : undef;
}

# Clear what a run that failed or died left of an update: a stage tree goes; a backup whose
# cache dir is missing holds the last good cache and is renamed back; any other backup goes.
# Only safe while no resolve runs – the caller holds the sync lock. Never throws.
sub sweep_cache {
  my ( $class, $cache_root ) = @_;
  opendir( my $dh, $cache_root ) or return;
  my @names = sort readdir $dh;
  closedir $dh;
  for my $name (@names) {
    my ( $hash, $kind ) = $name =~ $LEFTOVER or next;
    my $p = path_join( $cache_root, $name );
    eval {
      if ( $kind eq 'backup' ) {
        my $dir  = path_join( $cache_root, $hash );
        my $tree = path_join( $p, 'tree' );
        rename $tree, $dir if !-e $dir && lstat($tree) && -d _;
      }
      path($p)->remove_tree( { safe => 0 } );
      1;
    };
  }
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Source::Url - A url source: an https .tar.gz, conditional GET, staged swap into the shared cache

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Skilletor::Source::Url;

  my $src = Skilletor::Source::Url->new(
    url        => 'https://skills.example.com/skills.tar.gz',
    cache_root => $cache_root,
  );
  my $loc = $src->resolve;   # { dir, version => 'etag:"abc"' or 'sha256:…', warning? }
  my $moved = $src->check( $loc->{version} );

=head1 DESCRIPTION

The reference's C<sources/url.ts> (spec §4.4, §9). L</resolve> GETs the
tarball with the cache's ETag as C<If-None-Match>; a 304 reuses the cache, a
200 is unpacked by L<Skilletor::Tar> into a C<< <hash>.stage-XXXXXX >> tree
next to the cache and swapped in through a C<< <hash>.backup-XXXXXX >> tree,
so a reader never sees half a tree. The cache keeps its version in
C<.skilletor-version> (C<format 2>, then the version): the ETag, or the
archive's sha256 when the server sends none. A failed download serves the
cache with a warning; an unsafe archive is an error, never a fallback.

Requests carry the headers Node's C<fetch> sends (C<user-agent: node>,
C<accept-encoding: gzip, deflate>, …) and a compressed response is decoded as
C<fetch> decodes it, so a server answers both implementations alike – the same
ETag, the same version, the same lock.

=head2 url

The tarball's https URL.

=head2 cache_root

Where the caches live (L<Skilletor::Cache/cache_root>).

=head2 timeout_ms

Default 60000. L<HTTP::Tiny>'s timeout is per read, not for the whole request.

=head2 allow_http

Tests only: permits C<http://127.0.0.1> and C<http://localhost>.

=head2 http

The L<HTTP::Tiny> agent; inject one to stub the network.

=head2 cache_dir

This source's cache directory (L<Skilletor::Cache/url_cache_dir>).

=head2 resolve

C<< { dir, version, warning? } >>; see L</DESCRIPTION>.

=head2 cached

C<< { dir, version } >> of the cache without a request – what L</resolve>
serves when its download fails (C<unknown> without a version file), minus the
warning (a Perl addition for offline callers). Throws
L<Skilletor::Error::Source> when there is no cache.

=head2 check

  $src->check($cached_version);

A HEAD request: changed unless both the server and C<$cached_version> have an
ETag and they are equal.

=head2 cache_version

  $src->cache_version($dir);

=head2 sweep_cache

  Skilletor::Source::Url->sweep_cache($cache_root);

=head2 CACHE_FORMAT

C<format 2>, the first line of a current version file.

=head1 SUPPORT

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
