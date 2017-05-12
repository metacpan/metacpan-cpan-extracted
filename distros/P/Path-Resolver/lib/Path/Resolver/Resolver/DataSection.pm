package Path::Resolver::Resolver::DataSection;
{
  $Path::Resolver::Resolver::DataSection::VERSION = '3.100454';
}
# ABSTRACT: find content in a package's Data::Section content
use Moose;
with 'Path::Resolver::Role::Resolver';

use namespace::autoclean;

use File::Spec::Unix;
use Moose::Util::TypeConstraints;
use Path::Resolver::SimpleEntity;

sub native_type { class_type('Path::Resolver::SimpleEntity') }


has module => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);


has data_method => (
  is  => 'ro',
  isa => 'Str',
  default => 'section_data',
);

sub BUILD {
  my ($self) = @_;
  my $module = $self->module;
  eval "require $module; 1" or die;
}

sub entity_at {
  my ($self, $path) = @_;

  my $filename = File::Spec::Unix->catfile(@$path);
  my $method   = $self->data_method;
  my $content_ref = $self->module->$method($filename);

  return unless defined $content_ref;

  return Path::Resolver::SimpleEntity->new({ content_ref => $content_ref });
}

1;

__END__

=pod

=head1 NAME

Path::Resolver::Resolver::DataSection - find content in a package's Data::Section content

=head1 VERSION

version 3.100454

=head1 SYNOPSIS

  my $resolver = Path::Resolver::Resolver::DataSection->new({
    module => 'YourApp::Config::InData',
  });

  my $simple_entity = $resolver->entity_at('foo/bar.txt');

This class assumes that you will give it the name of another package and that
that package uses L<Data::Section|Data::Section> to retrieve named content from
its C<DATA> blocks and those of its parent classes.

The native type of this resolver is a class type of
L<Path::Resolver::SimpleEntity|Path::Resolver::SimpleEntity> and it has no
default converter.

=head1 ATTRIBUTES

=head2 module

This is the name of the module to load and is also used as the package (class)
on which to call the data-finding method.

=head2 data_method

This attribute may be given to supply a method name to call to find content in
a package.  The default is Data::Section's default: C<section_data>.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
