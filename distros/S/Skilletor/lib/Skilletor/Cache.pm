package Skilletor::Cache;
# ABSTRACT: Where a git or url source is cached – the reference's cache naming

use strict;
use warnings;

use Digest::SHA qw( sha256_hex );
use Exporter qw( import );
use Skilletor::FSUtil qw( encode_text path_join );
use Skilletor::JSON qw( js_stringify );

our $VERSION = '0.001';

our @EXPORT_OK = qw( cache_root cache_name git_identity git_cache_dir url_cache_dir CACHE_NAME_RE );

# The name a cache dir has: 16 hex digits of a sha256 (git and url caches share the scheme).
use constant CACHE_NAME_RE => qr/\A[0-9a-f]{16}\z/;

sub cache_root {
  my ( $home ) = @_;
  return path_join( $home, '.claude', 'skilletor', 'cache' );
}

sub cache_name {
  my ( $identity ) = @_;
  return substr( sha256_hex( encode_text($identity) ), 0, 16 );
}

# An unpinned source keeps the legacy URL-only identity; an explicit ref never shares it.
sub git_identity {
  my ( $url, $ref ) = @_;
  return ( defined $ref && length $ref ) ? js_stringify( [ $url, $ref ] ) : $url;
}

sub git_cache_dir {
  my ( $root, $url, $ref ) = @_;
  return path_join( $root, cache_name( git_identity( $url, $ref ) ) );
}

sub url_cache_dir {
  my ( $root, $url ) = @_;
  return path_join( $root, cache_name($url) );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Cache - Where a git or url source is cached – the reference's cache naming

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Skilletor::Cache qw( cache_root git_cache_dir url_cache_dir );

  my $root = cache_root( $ENV{HOME} );     # ~/.claude/skilletor/cache
  my $dir  = git_cache_dir( $root, 'https://github.com/Getty/skills', 'main' );
  my $tgz  = url_cache_dir( $root, 'https://skills.example.com/skills.tar.gz' );

=head1 DESCRIPTION

Both implementations fetch into one cache, so they must name every cache
directory alike. A git source's identity is its URL alone when it has no
C<ref> (the cache layout before skilletor 0.3.1, kept for unpinned sources),
else C<JSON.stringify([url, ref])>; a url source's identity is its URL. The
directory is the first 16 hex digits of the sha256 of the identity's UTF-8
bytes, beneath the cache root.

=head2 cache_root

  cache_root($home);

C<< <home>/.claude/skilletor/cache >>, the cache root of a CLI run.

=head2 cache_name

The 16-hex-digit directory name of an identity.

=head2 git_identity

  git_identity( $url, $ref );

=head2 git_cache_dir

  git_cache_dir( $root, $url, $ref );

=head2 url_cache_dir

  url_cache_dir( $root, $url );

=head2 CACHE_NAME_RE

The pattern a cache directory's name matches; the sweeps touch nothing else.

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
