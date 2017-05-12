package Path::Resolver::Resolver::FileSystem;
{
  $Path::Resolver::Resolver::FileSystem::VERSION = '3.100454';
}
# ABSTRACT: find files in the filesystem
use Moose;
with 'Path::Resolver::Role::FileResolver';

use namespace::autoclean;

use Carp ();
use Cwd ();
use File::Spec;


has root => (
  is => 'rw',
  required    => 1,
  default     => sub { Cwd::cwd },
  initializer => sub {
    my ($self, $value, $set) = @_;
    my $abs_dir = File::Spec->rel2abs($value);
    $set->($abs_dir);
  },
);

sub entity_at {
  my ($self, $path) = @_;

  my $abs_path = File::Spec->catfile(
    $self->root,
    @$path,
  );

  return unless -e $abs_path and -f _;

  Path::Class::File->new($abs_path);
}

1;

__END__

=pod

=head1 NAME

Path::Resolver::Resolver::FileSystem - find files in the filesystem

=head1 VERSION

version 3.100454

=head1 SYNOPSIS

  my $resolver = Path::Resolver::Resolver::FileSystem->new({
    root => '/etc/myapp_config',
  });

  my $simple_entity = $resolver->entity_at('foo/bar.txt');

This resolver looks for files on disk under the given root directory.

This resolver does the
L<Path::Resolver::Role::FileResolver|Path::Resolver::Role::FileResolver> role,
meaning its native type is Path::Resolver::Types::AbsFilePath and it has a
default converter to convert to Path::Resolver::SimpleEntity.

=head1 ATTRIBUTES

=head2 root

This is the root on the filesystem under which to look.  If it is relative, it
will be resolved to an absolute path when the resolver is instantiated.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
