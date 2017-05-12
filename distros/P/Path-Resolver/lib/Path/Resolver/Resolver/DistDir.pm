package Path::Resolver::Resolver::DistDir;
{
  $Path::Resolver::Resolver::DistDir::VERSION = '3.100454';
}
# ABSTRACT: find content in a prebound CPAN distribution's "ShareDir"
use Moose;
with 'Path::Resolver::Role::FileResolver';

use namespace::autoclean;

use File::ShareDir ();
use File::Spec;


has dist_name => (
  is  => 'ro',
  isa => 'Str',
  required => 1,
);

sub entity_at {
  my ($self, $path) = @_;
  my $dir = File::ShareDir::dist_dir($self->dist_name);

  my $abs_path = File::Spec->catfile(
    $dir,
    File::Spec->catfile(@$path),
  );

  return Path::Class::File->new($abs_path);
}

1;

__END__

=pod

=head1 NAME

Path::Resolver::Resolver::DistDir - find content in a prebound CPAN distribution's "ShareDir"

=head1 VERSION

version 3.100454

=head1 SYNOPSIS

  my $resolver = Path::Resolver::Resolver::DistDir->new({
    dist_name => 'YourApp-Files',
  });

  my $simple_entity = $resolver->entity_at('foo/bar.txt');

This resolver looks for files on disk in the shared resource directory of the
named distribution.  For more information on sharedirs, see
L<File::ShareDir|File::ShareDir>.

This resolver does the
L<Path::Resolver::Role::FileResolver|Path::Resolver::Role::FileResolver> role,
meaning its native type is Path::Resolver::Types::AbsFilePath and it has a
default converter to convert to Path::Resolver::SimpleEntity.

=head1 ATTRIBUTES

=head2 dist_name

This is the name of a dist (like "Path-Resolver").  When looking for content,
the resolver will look in the dist's shared content directory, as located by
L<File::ShareDir|File::ShareDir>.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
