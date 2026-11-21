package Skilletor::Render::Loader;
# ABSTRACT: A Nunjucks loader confined to an item's source root – the reference's makeLoader

use Moo;
use Path::Tiny qw( path );
use Skilletor::Error::Render;
use Skilletor::FSUtil qw( decode_utf8_lossy encode_text path_resolve );
use namespace::clean;

extends 'Text::Nunjucks::Loader';

our $VERSION = '0.008000';

has root => (
  is       => 'ro',
  required => 1,
);

# The reference's loader has no isRelative, so Nunjucks never resolves a name against the
# template that includes it: `./x.md` and `../x.md` are relative to the source root as well.
sub is_relative { 0 }

sub get_source {
  my ( $self, $name ) = @_;
  my $base = path_resolve( $self->root );
  my $path = path_resolve( $base, $name );
  Skilletor::Error::Render->throw( 'template escapes source root: '.$name ) if $path ne $base && index( $path, $base.'/' ) != 0;
  # readFileSync(path, "utf8"): whatever cannot be read (missing, a directory) is no template.
  my $bytes = eval { path( encode_text($path) )->slurp_raw };
  return undef unless defined $bytes;
  return { src => decode_utf8_lossy($bytes), path => $path, noCache => !!1 };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Render::Loader - A Nunjucks loader confined to an item's source root – the reference's makeLoader

=head1 VERSION

version 0.008000

=head1 SYNOPSIS

  use Text::Nunjucks::Environment;
  use Skilletor::Render::Loader;

  my $env = Text::Nunjucks::Environment->new( Skilletor::Render::Loader->new( root => $source_dir ),
    { autoescape => !!0, throwOnUndefined => !!1 } );

=head1 DESCRIPTION

The loader L<Skilletor::Render> renders an item's templates through: a
L<Text::Nunjucks::Loader> that serves files of one source tree, the reference's
C<makeLoader> (spec §5). A template, an include, an import or a macro file is
looked up by its path relative to the source root; a name that resolves outside
it – C<../x.md>, C</etc/passwd> – throws a L<Skilletor::Error::Render>
C<< template escapes source root: <name> >>. A file is read as UTF-8 the way
Node reads it (an ill-formed sequence becomes U+FFFD) and never cached.

=head2 root

The source root, the item's source tree.

=head2 get_source

  $loader->get_source('snippets/shared.md');   # { src, path, noCache }

The template's source and absolute path, or undef when there is no such file.

=head2 is_relative

False for every name: a name is always relative to the source root, never to
the template that includes it.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/skilletor/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
