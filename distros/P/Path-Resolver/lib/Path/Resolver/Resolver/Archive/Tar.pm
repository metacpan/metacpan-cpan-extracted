package Path::Resolver::Resolver::Archive::Tar 3.100455;
# ABSTRACT: find content inside a tar archive
use Moose;
use Moose::Util::TypeConstraints;
with 'Path::Resolver::Role::Resolver';

use namespace::autoclean;

use Archive::Tar;
use File::Spec::Unix;
use Path::Resolver::SimpleEntity;

#pod =head1 SYNOPSIS
#pod
#pod   my $resolver = Path::Resolver::Resolver::Archive::Tar->new({
#pod     archive => 'archive-file.tar.gz',
#pod   });
#pod
#pod   my $simple_entity = $resolver->entity_at('foo/bar.txt');
#pod
#pod This resolver looks for files inside a tar archive or a compressed tar archive.
#pod It uses L<Archive::Tar|Archive::Tar>, and can read any archive understood by
#pod that library.
#pod
#pod The native type of this resolver is a class type of
#pod L<Path::Resolver::SimpleEntity|Path::Resolver::SimpleEntity> and it has no
#pod default converter.
#pod
#pod =cut

sub native_type { class_type('Path::Resolver::SimpleEntity') }

#pod =attr archive
#pod
#pod This attribute stores the Archive::Tar object in which content will be
#pod resolved.  A simple string may be passed to the constructor to be used as an
#pod archive filename.
#pod
#pod =cut

has archive => (
  is  => 'ro',
  required    => 1,
  initializer => sub {
    my ($self, $value, $set) = @_;

    my $archive = ref $value ? $value : Archive::Tar->new($value);

    confess("$value is not a valid archive value")
      unless class_type('Archive::Tar')->check($archive);
    
    $set->($archive);
  },
);

#pod =attr root
#pod
#pod If given, this attribute specifies a root inside the archive under which to
#pod look.  This is useful when dealing with an archive in which all content is
#pod under a common directory.
#pod
#pod =cut

has root => (
  is => 'ro',
  required => 0,
);

sub entity_at {
  my ($self, $path) = @_;
  my $root = $self->root;
  my @root = (length $root) ? $root : ();

  my $filename = File::Spec::Unix->catfile(@root, @$path);
  return unless $self->archive->contains_file($filename);
  my $content = $self->archive->get_content($filename);

  Path::Resolver::SimpleEntity->new({ content_ref => \$content });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Resolver::Resolver::Archive::Tar - find content inside a tar archive

=head1 VERSION

version 3.100455

=head1 SYNOPSIS

  my $resolver = Path::Resolver::Resolver::Archive::Tar->new({
    archive => 'archive-file.tar.gz',
  });

  my $simple_entity = $resolver->entity_at('foo/bar.txt');

This resolver looks for files inside a tar archive or a compressed tar archive.
It uses L<Archive::Tar|Archive::Tar>, and can read any archive understood by
that library.

The native type of this resolver is a class type of
L<Path::Resolver::SimpleEntity|Path::Resolver::SimpleEntity> and it has no
default converter.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 ATTRIBUTES

=head2 archive

This attribute stores the Archive::Tar object in which content will be
resolved.  A simple string may be passed to the constructor to be used as an
archive filename.

=head2 root

If given, this attribute specifies a root inside the archive under which to
look.  This is useful when dealing with an archive in which all content is
under a common directory.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
