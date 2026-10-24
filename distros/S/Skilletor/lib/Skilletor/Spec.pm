package Skilletor::Spec;
# ABSTRACT: Resolve an add shorthand (owner/repo, a forge link, a URL, a path) to a source

use strict;
use warnings;

use Encode ();
use Exporter qw( import );
use Skilletor::Entry qw( is_source_name );
use Skilletor::Error::Spec;
use Skilletor::JSON qw( js_stringify );
use Skilletor::JSString qw( js_lc js_trim js_blank js_ws_re );
use Skilletor::URL qw( parse_url );

our $VERSION = '0.001';

our @EXPORT_OK = qw( resolve_spec decode_uri_component normalize_name );

use constant WIN32 => $^O eq 'MSWin32';

# The known forges (never probed), by host, with the name their errors use.
my %FORGES = (
  'github.com' => 'GitHub', 'gitlab.com' => 'GitLab', 'codeberg.org' => 'Codeberg',
  'hf.co'      => 'Hugging Face', 'huggingface.co' => 'Hugging Face',
);
my $DEFAULT_REPO  = 'skills';
my $FALLBACK_NAME = 'source';
my $FORMS = 'expected a local path (/path, ./path, ../path, ~/path), scheme://..., transport::address, user@host:path, '
  .'github:owner[/repo], owner[/repo] or host.tld[/path]';
my $SCHEME    = qr/\A[a-z][a-z0-9+.\-]*:(?=\/\/)/i;
my $TRANSPORT = qr/\A[A-Za-z][A-Za-z0-9+.\-]*::/;
my $WS = js_ws_re();
my $NOT_IN_SEGMENT = qr/(?:$WS|\p{Cc}|[:\@])/;

sub _fail { Skilletor::Error::Spec->throw( $_[0] ) }

sub normalize_name {
  my ( $raw ) = @_;
  my $s = js_lc($raw);
  $s =~ s/\.git\z//;
  $s =~ s/[^a-z0-9-]+/-/g;
  $s =~ s/\A-+|-+\z//g;
  return $s;
}

sub _basename {
  my ( $path ) = @_;
  my @parts = grep { length } split( WIN32 ? qr{[\\/]} : qr{/}, $path );
  return @parts ? $parts[-1] : $path;
}

sub _is_local {
  my ( $spec ) = @_;
  return 1 if $spec =~ m{\A(?:/|\./|\.\./|~)};
  return WIN32 && ( $spec =~ m{\A[A-Za-z]:[\\/]} || $spec =~ m{\A\\\\} || $spec =~ m{\A\.\.?\\} ) ? 1 : 0;
}

sub _has_scheme { $_[0] =~ $SCHEME ? 1 : 0 }

sub _lower_scheme {
  my ( $spec ) = @_;
  ( my $s = $spec ) =~ s/($SCHEME)/lc $1/e;
  return $s;
}

sub _helper_address {
  my ( $spec ) = @_;
  return undef unless $spec =~ /($TRANSPORT)/;
  my $len = length $1;
  return length($spec) > $len ? substr( $spec, $len ) : undef;
}

sub _check_github {
  my ( $spec, $owner, $repo ) = @_;
  unless ( $owner =~ /\A[A-Za-z0-9-]+\z/ ) {
    _fail( 'cannot resolve "'.$spec.'": GitHub owner "'.$owner.'" may only contain ASCII letters, digits and "-"; '.$FORMS );
  }
  if ( defined $repo && $repo !~ /\A[A-Za-z0-9._-]+\z/ ) {
    _fail( 'cannot resolve "'.$spec.'": GitHub repo "'.$repo.'" may only contain ASCII letters, digits, ".", "_" and "-"; '.$FORMS );
  }
}

sub _check_forge {
  my ( $spec, $forge, $owner, $repo ) = @_;
  for my $pair ( [ owner => $owner ], [ repo => $repo ] ) {
    my ( $what, $seg ) = @$pair;
    if ( $seg =~ $NOT_IN_SEGMENT ) {
      _fail( 'cannot resolve "'.$spec.'": '.$forge.' '.$what.' "'.$seg
        .'" must not contain whitespace, control characters, ":" or "@"; '.$FORMS );
    }
  }
}

sub _is_scp_like { $_[0] =~ m{\A[^\@/]+\@[^:/]+:} ? 1 : 0 }

sub _is_tarball { $_[0] =~ /\.(?:tar\.gz|tgz)\z/i ? 1 : 0 }

sub _repo_name {
  my ( $owner, $repo ) = @_;
  my $name = defined $repo ? normalize_name($repo) : '';
  return ( length $name && $name ne $DEFAULT_REPO ) ? $name : normalize_name($owner);
}

sub _name_from_path {
  my ( $path ) = @_;
  my @segs = grep { length } split m{/}, $path;
  return normalize_name($path) unless @segs;
  return _repo_name( $segs[0], @segs > 1 ? $segs[-1] : undef );
}

sub _name_from_url {
  my ( $spec, $kind ) = @_;
  if ( _is_scp_like($spec) ) {
    my $path = substr $spec, index( $spec, ':' ) + 1;
    return _name_from_path($path) if $kind eq 'git';
    my ($first) = split m{/}, $path, 2;
    return normalize_name( _basename( $first // '' ) );
  }
  my $u = parse_url($spec);
  return normalize_name($spec) unless $u;
  my @segs = grep { length } split m{/}, $u->{pathname};
  return _name_from_path( $u->{pathname} ) if $kind eq 'git' && @segs;
  return normalize_name( $u->{hostname} );
}

sub _name_from_helper {
  my ( $address ) = @_;
  return ( _has_scheme($address) || _is_scp_like($address) ) ? _name_from_url( $address, 'git' ) : _name_from_path($address);
}

# decodeURIComponent: %XX runs must be UTF-8 of a scalar value; undef where it throws URIError.
sub decode_uri_component {
  my ( $s ) = @_;
  my $out = '';
  my $i   = 0;
  my $len = length $s;
  while ( $i < $len ) {
    my $c = substr $s, $i, 1;
    if ( $c ne '%' ) { $out .= $c; $i++; next }
    my $byte = _hex_at( $s, $i );
    return undef unless defined $byte;
    $i += 3;
    if ( $byte < 0x80 ) { $out .= chr $byte; next }
    my $n = $byte >= 0xC0 && $byte < 0xE0 ? 2 : $byte >= 0xE0 && $byte < 0xF0 ? 3 : $byte >= 0xF0 && $byte < 0xF8 ? 4 : 0;
    return undef unless $n;
    my @bytes = ($byte);
    for ( 2 .. $n ) {
      return undef unless substr( $s, $i, 1 ) eq '%';
      my $cont = _hex_at( $s, $i );
      return undef unless defined $cont && ( $cont & 0xC0 ) == 0x80;
      push @bytes, $cont;
      $i += 3;
    }
    my $copy = pack 'C*', @bytes;
    my $char = eval { Encode::decode( 'UTF-8', $copy, Encode::FB_CROAK() ) };
    return undef unless defined $char && length $char == 1;
    my $cp = ord $char;
    return undef if $cp >= 0xD800 && $cp <= 0xDFFF;
    $out .= $char;
  }
  return $out;
}

sub _hex_at {
  my ( $s, $i ) = @_;
  my $h = substr $s, $i + 1, 2;
  return undef unless length $h == 2 && $h =~ /\A[0-9A-Fa-f]{2}\z/;
  return hex $h;
}

sub _forge_link {
  my ( $spec, $written, $rest, $explicit ) = @_;
  my $host  = js_lc($written);
  my $forge = $FORGES{$host};
  my ($before) = $rest =~ /\A([^?#]*)/;
  my @segs = grep { length } split m{/}, $before;
  my $hf = ( $forge eq 'Hugging Face' && @segs && ( $segs[0] eq 'datasets' || $segs[0] eq 'spaces' ) ) ? 1 : 0;
  my @prefix = $hf ? ( shift @segs ) : ();
  my $owner = $segs[0];
  if ( !defined $owner || js_blank($owner) ) {
    return { kind => 'git', value => $explicit, derivedName => _name_from_url( $explicit, 'git' ) } if defined $explicit;
    _fail( 'cannot resolve "'.$spec.'": expected '.$written.'/'.join( '', map { $_.'/' } @prefix ).'owner[/repo]' );
  }
  my @tail = grep { !js_blank($_) } @segs[ 1 .. $#segs ];
  my ( @repo_path, @view );
  if ( $host eq 'gitlab.com' ) {
    my ($dash) = grep { $tail[$_] eq '-' } 0 .. $#tail;
    if ( defined $dash ) {
      @repo_path = @tail[ 0 .. $dash - 1 ];
      @view      = @tail[ $dash + 1 .. $#tail ];
    }
    else {
      @repo_path = @tail;
    }
  }
  else {
    @repo_path = @tail ? ( $tail[0] ) : ();
    @view      = @tail[ 1 .. $#tail ];
  }
  my $repo = @repo_path ? $repo_path[-1] : undef;
  if ( defined $explicit && !@view ) {
    return { kind => 'git', value => $explicit, derivedName => _name_from_url( $explicit, 'git' ) };
  }
  if ( $host eq 'github.com' ) {
    _check_github( $spec, $owner, $repo );
  }
  else {
    _check_forge( $spec, $written, $owner, $_ ) for ( @repo_path ? @repo_path : ($DEFAULT_REPO) );
  }
  my $value = 'https://'.$host.'/'.join( '/', @prefix, $owner, ( @repo_path ? @repo_path : ($DEFAULT_REPO) ) );
  my %resolved = ( kind => 'git', value => $value, derivedName => _repo_name( $owner, $repo ) );
  return \%resolved unless @view;

  my $fail = sub { _fail( 'cannot resolve "'.$spec.'": '.$_[0] ) };
  my $page = sub { $fail->( 'a '.$forge.' '.js_stringify( join '/', @view ).' page is not a source; add '.$value ) };
  my $decode = sub {
    my ( $seg ) = @_;
    my $d = decode_uri_component($seg);
    $fail->( js_stringify($seg).' in the link is not a valid %-escape' ) unless defined $d;
    return $d;
  };
  my $tree = sub {
    my ( $at ) = @_;
    $fail->( 'a '.$forge.' tree link without a ref; add '.$value ) unless defined $view[$at];
    my %link = ( %resolved, ref => $decode->( $view[$at] ) );
    my @sub = map { $decode->($_) } @view[ $at + 1 .. $#view ];
    $link{path} = join '/', @sub if @sub;
    return \%link;
  };
  my $pin = sub {
    my ( $at, $what ) = @_;
    unless ( defined $view[$at] ) {
      $fail->( 'a '.$forge.' '.$what.' link without a '.( $what eq 'release' ? 'tag' : 'commit' ).'; add '.$value );
    }
    $page->() if @view > $at + 1;
    return { %resolved, ref => $decode->( $view[$at] ) };
  };
  my $file = sub {
    my ( $at, $tree_of ) = @_;
    my $ref = $view[$at];
    my $pinned = defined $ref ? ', or '.$tree_of->($ref).' to pin ref "'.$ref.'"' : '';
    $fail->( 'a '.$forge.' file link; a source is a repository, not a file: add '.$value.$pinned );
  };
  my ( $v0, $v1 ) = @view;
  $v1 //= undef;
  if ( $forge eq 'GitHub' || $forge eq 'Hugging Face' ) {
    return $tree->(1) if $v0 eq 'tree';
    if ( $v0 eq 'blob' || ( $forge eq 'Hugging Face' && ( $v0 eq 'resolve' || $v0 eq 'raw' ) ) ) {
      $file->( 1, sub { $value.'/tree/'.$_[0] } );
    }
    return $pin->( 1, 'commit' ) if $v0 eq 'commit';
    return $pin->( 2, 'release' ) if $forge eq 'GitHub' && $v0 eq 'releases' && defined $v1 && $v1 eq 'tag';
    $page->();
  }
  if ( $forge eq 'GitLab' ) {
    return $tree->(1) if $v0 eq 'tree';
    $file->( 1, sub { $value.'/-/tree/'.$_[0] } ) if $v0 eq 'blob' || $v0 eq 'raw';
    return $pin->( 1, 'commit' ) if $v0 eq 'commit';
    return $pin->( 1, 'release' ) if $v0 eq 'tags' || $v0 eq 'releases';
    $page->();
  }
  # Codeberg (Forgejo): src|raw|media/branch|tag|commit/<ref>
  my %kinds = map { $_ => 1 } qw( branch tag commit );
  return $tree->(2) if $v0 eq 'src' && defined $v1 && $kinds{$v1};
  $fail->( 'a '.$forge.' tree link without a ref; add '.$value ) if $v0 eq 'src' && !defined $v1;
  if ( ( $v0 eq 'raw' || $v0 eq 'media' ) && defined $v1 && $kinds{$v1} ) {
    $file->( 2, sub { $value.'/src/'.$v1.'/'.$_[0] } );
  }
  return $pin->( 1, 'commit' ) if $v0 eq 'commit';
  return $pin->( 2, 'release' ) if $v0 eq 'releases' && defined $v1 && $v1 eq 'tag';
  $page->();
}

sub resolve_spec {
  my ( $spec, $probe ) = @_;
  my $r = _resolve_address( $spec, $probe );
  return is_source_name( $r->{derivedName} ) ? $r : { %$r, derivedName => $FALLBACK_NAME };
}

sub _resolve_address {
  my ( $spec, $probe ) = @_;
  my $s = js_trim($spec);

  # An empty spec would be a bare word; an address kept verbatim must not reach git as an option.
  _fail( 'cannot resolve "'.$spec.'": empty source; '.$FORMS ) if $s eq '';
  _fail( 'cannot resolve "'.$spec.'": a source must not start with "-"' ) if $s =~ /\A-/;

  # 1. Local paths.
  return { kind => 'local', value => $s, derivedName => normalize_name( _basename($s) ) } if _is_local($s);

  # 2. Explicit URLs, scp-like and transport::address forms: kept verbatim, but a lower-case
  #    scheme; an https:// link to a known forge reads as in 4.
  my $address = _helper_address($s);
  return { kind => 'git', value => $s, derivedName => _name_from_helper($address) } if defined $address;
  if ( _has_scheme($s) || _is_scp_like($s) ) {
    my $value = _lower_scheme($s);
    my $kind  = _is_tarball($value) ? 'url' : 'git';
    if ( $kind eq 'git' && $value =~ m{\A(https://([^/?#]+)/)} && exists $FORGES{ js_lc($2) } ) {
      my ( $whole, $host ) = ( $1, $2 );
      my ($explicit) = $value =~ /\A([^?#]*)/;
      return _forge_link( $spec, $host, substr( $value, length $whole ), $explicit );
    }
    return { kind => $kind, value => $value, derivedName => _name_from_url( $value, $kind ) };
  }

  # 3. github:owner/repo, in any case.
  if ( $s =~ /\Agithub:/i ) {
    my $path = substr $s, length 'github:';
    my ($first) = $path =~ m{\A([^/?#]*)};
    _fail( 'cannot resolve "'.$spec.'": expected github:owner[/repo]' ) if js_blank($first);
    return _forge_link( $spec, 'github.com', $path );
  }

  my $slash     = index $s, '/';
  my $first_seg = $slash == -1 ? $s : substr( $s, 0, $slash );
  my $rest      = $slash == -1 ? '' : substr( $s, $slash + 1 );

  # 4. A known forge with an owner (never probed).
  return _forge_link( $spec, $first_seg, $rest ) if exists $FORGES{ js_lc($first_seg) } && $slash != -1;

  # 5. and 6. take a first segment without a dot as a GitHub owner, which has no colon.
  my $colon = index $first_seg, ':';
  if ( $colon != -1 && index( $first_seg, '.' ) == -1 ) {
    _fail( 'cannot resolve "'.$spec.'": unknown prefix "'.substr( $first_seg, 0, $colon + 1 ).'"; '.$FORMS );
  }

  # 5. and 7. take a colon after a dotted host as its port, a number.
  my $host_port = substr $first_seg, rindex( $first_seg, '@' ) + 1;
  my $port_at   = index $host_port, ':';
  if ( $port_at != -1 && substr( $host_port, $port_at + 1 ) !~ /\A[0-9]+\z/ ) {
    _fail( 'cannot resolve "'.$spec.'": port "'.substr( $host_port, $port_at + 1 ).'" of '
      .substr( $host_port, 0, $port_at ).' is not a number; '.$FORMS );
  }

  # 5. A single token.
  if ( $slash == -1 ) {
    if ( index( $first_seg, '.' ) == -1 ) {
      _check_github( $spec, $first_seg, undef );
      return { kind => 'git', value => 'https://github.com/'.$first_seg.'/'.$DEFAULT_REPO, derivedName => normalize_name($first_seg) };
    }
    return _probe_generic( 'https://'.$first_seg.'/'.$DEFAULT_REPO, $first_seg, $spec, $probe );
  }

  # 6. owner/repo, the first segment without a dot: GitHub, read as a github.com link.
  return _forge_link( $spec, 'github.com', $s ) if index( $first_seg, '.' ) == -1;

  # 7. host.tld[/path]: a generic host, probed.
  ( my $path = $rest ) =~ s{/+\z}{};
  my $base = length $path ? 'https://'.$first_seg.'/'.$path : 'https://'.$first_seg.'/'.$DEFAULT_REPO;
  return _probe_generic( $base, $first_seg, $spec, $probe );
}

sub _probe_generic {
  my ( $base, $host, $original, $probe ) = @_;
  my $result = $probe->($base) // {};
  return { kind => 'git', value => $base, derivedName => normalize_name($host) } if $result->{git};
  return { kind => 'url', value => $base.'.tar.gz', derivedName => normalize_name($host) } if $result->{tarball};
  _fail( 'cannot resolve "'.$original.'": neither '.$base.' (git) nor '.$base.'.tar.gz (tarball) responded' );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Spec - Resolve an add shorthand (owner/repo, a forge link, a URL, a path) to a source

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Skilletor::Spec qw( resolve_spec );

  my $r = resolve_spec( 'Getty/karr', $probe );
  # { kind => 'git', value => 'https://github.com/Getty/karr', derivedName => 'karr' }

  my $t = resolve_spec( 'https://github.com/Getty/skills/tree/main/perl', $probe );
  # { kind => 'git', value => 'https://github.com/Getty/skills', derivedName => 'getty',
  #   ref => 'main', path => 'perl' }

=head1 DESCRIPTION

The reference's C<spec.ts> (spec §4.2): what C<skilletor add> makes of what
the user typed, once, at add time – the config always stores the explicit
form. Local paths, explicit URLs (any scheme, scp-like, git's
C<transport::address>), C<github:owner/repo>, known forges (GitHub, GitLab,
Codeberg, Hugging Face) including their tree, commit, tag and release links,
bare owners and C<owner/repo> resolve without the network; only a generic
C<host.tld[/path]> is probed. The probe is the caller's: a code reference
called with the base URL, answering C<< { git => 1 } >>, C<< { tarball => 1 } >>
or neither.

Errors are L<Skilletor::Error::Spec> with the reference's messages. The derived
name is always a valid source name (C<source> when nothing of the spec is left).

=head2 resolve_spec

  resolve_spec( $spec, $probe );

C<< { kind => 'git' | 'url' | 'local', value, derivedName, ref?, path? } >> –
the reference's field names.

=head2 normalize_name

Lower case, a trailing C<.git> dropped, every run of other characters than
C<a-z0-9-> one C<->, no C<-> at either end.

=head2 decode_uri_component

C<decodeURIComponent>; C<undef> where it throws.

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
