package Skilletor::Source::Local;
# ABSTRACT: A source read straight from a local directory (author mode)

use Moo;
use Skilletor::Error::Source;
use Skilletor::FSUtil qw( path_join );
use namespace::clean;

with 'Skilletor::Role::Source';

our $VERSION = '0.001';

has local_path => (
  is       => 'ro',
  required => 1,
);

has home => (
  is => 'ro',
);

has dir => (
  is       => 'lazy',
  init_arg => undef,
);

sub _build_dir {
  my ( $self ) = @_;
  return defined $self->home ? $self->expand_home( $self->local_path, $self->home ) : $self->local_path;
}

# A leading ~ or ~/ against the home; other paths pass through.
sub expand_home {
  my ( $self, $path, $home ) = @_;
  return $home if $path eq '~';
  return path_join( $home, substr( $path, 2 ) ) if $path =~ m{\A~/} || ( $^O eq 'MSWin32' && $path =~ m{\A~\\} );
  return $path;
}

sub exists { -d $_[0]->dir ? 1 : 0 }

sub resolve {
  my ( $self ) = @_;
  Skilletor::Error::Source->throw( 'local source directory does not exist: '.$self->dir ) unless -e $self->dir;
  return { dir => $self->dir, version => 'local' };
}

# No network to avoid: the directory itself.
sub cached { $_[0]->resolve }

# Local sources are always re-rendered.
sub check { 1 }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Source::Local - A source read straight from a local directory (author mode)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Skilletor::Source::Local;

  my $src = Skilletor::Source::Local->new( local_path => '~/dev/skills', home => $ENV{HOME} );
  my $loc = $src->resolve;    # { dir => '/home/me/dev/skills', version => 'local' }

=head1 DESCRIPTION

The reference's C<sources/local.ts> (spec §4.4): a directory read directly, no
fetch and no cache. The version is always C<local> and L</check> always says
changed, so every run re-renders it. A missing directory is no error until
L</resolve>: L</exists> lets the caller fall back to the source's git or url.

=head2 local_path

The path as configured; a leading C<~> is expanded when L</home> is given.
Without C<home> the path is taken as is.

=head2 home

Stands in for C<~> in L</local_path>.

=head2 dir

The directory read.

=head2 expand_home

  $src->expand_home( '~/dev', '/home/me' );   # /home/me/dev

=head2 exists

True when L</dir> is a directory.

=head2 resolve

C<< { dir, version => 'local' } >>; throws L<Skilletor::Error::Source> for a missing directory.

=head2 cached

L</resolve>: a local source needs no network (the offline call the git and url
backends have too).

=head2 check

Always true: a local source is re-rendered every run.

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
