package Path::Resolver::Resolver::AnyDist 3.100455;
# ABSTRACT: find content in any installed CPAN distribution's "ShareDir"
use Moose;
with 'Path::Resolver::Role::FileResolver';

use namespace::autoclean;

use File::ShareDir ();
use File::Spec;
use Path::Class::File;

#pod =head1 SYNOPSIS
#pod
#pod   my $resolver = Path::Resolver::Resolver::AnyDist->new;
#pod
#pod   my $simple_entity = $resolver->entity_at('/MyApp-Config/foo/bar.txt');
#pod
#pod This resolver looks for files on disk in the shared resource directory of the
#pod distribution named by the first part of the path.  For more information on
#pod sharedirs, see L<File::ShareDir|File::ShareDir>.
#pod
#pod This resolver does the
#pod L<Path::Resolver::Role::FileResolver|Path::Resolver::Role::FileResolver> role,
#pod meaning its native type is Path::Resolver::Types::AbsFilePath and it has a
#pod default converter to convert to Path::Resolver::SimpleEntity.
#pod
#pod =cut

sub entity_at {
  my ($self, $path) = @_;
  my $dist_name = shift @$path;
  my $dir = File::ShareDir::dist_dir($dist_name);

  Carp::confess("invalid path: empty after dist specifier") unless @$path;

  my $abs_path = File::Spec->catfile(
    $dir,
    File::Spec->catfile(@$path),
  );

  return Path::Class::File->new($abs_path);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Resolver::Resolver::AnyDist - find content in any installed CPAN distribution's "ShareDir"

=head1 VERSION

version 3.100455

=head1 SYNOPSIS

  my $resolver = Path::Resolver::Resolver::AnyDist->new;

  my $simple_entity = $resolver->entity_at('/MyApp-Config/foo/bar.txt');

This resolver looks for files on disk in the shared resource directory of the
distribution named by the first part of the path.  For more information on
sharedirs, see L<File::ShareDir|File::ShareDir>.

This resolver does the
L<Path::Resolver::Role::FileResolver|Path::Resolver::Role::FileResolver> role,
meaning its native type is Path::Resolver::Types::AbsFilePath and it has a
default converter to convert to Path::Resolver::SimpleEntity.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
