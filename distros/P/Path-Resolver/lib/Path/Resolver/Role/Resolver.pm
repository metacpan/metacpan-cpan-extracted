package Path::Resolver::Role::Resolver 3.100455;
# ABSTRACT: resolving paths is just what resolvers do!
use Moose::Role;

use namespace::autoclean;

use File::Spec::Unix;
use MooseX::Types;

#pod =head1 DESCRIPTION
#pod
#pod A class that implements this role can be used to resolve paths into entities.
#pod They declare the type of entity that they will produce internally, and may have
#pod a mechanism for converting that entity into another type before returning it.
#pod
#pod =method entity_at
#pod
#pod   my $entity = $resolver->entity_at($path);
#pod
#pod This is the most important method in a resolver.  It is handed a unix-style
#pod filepath and does one of three things:
#pod
#pod =over
#pod
#pod =item * returns an entity if a suitable one can be found
#pod
#pod =item * returns undef if no entity can be found
#pod
#pod =item * raises an exception if the entity found is unsuitable or if an error occurs
#pod
#pod =back
#pod
#pod Much of the logic of this method is implemented by an C<around> modifier
#pod applied by the role.  This modifier will convert paths from strings into
#pod arrayrefs of path parts.
#pod
#pod Empty path parts are removed -- except for the first, which would represent the
#pod root are skipped, and the last, which would imply that you provided a path
#pod ending in /, which is a directory.
#pod
#pod If the resolver has a C<converter> (see below) then the found entity will be
#pod passed to the converter and the result will be returned.  Otherwise, the entity
#pod will be type-checked and returned.
#pod
#pod This means that to write a resolver, you must write a C<entity_at> method that
#pod accepts an arrayref of path parts (strings) and returns an object of the type
#pod indicated by the resolver's C<native_type> method (below).
#pod
#pod =cut

requires 'entity_at';

around entity_at => sub {
  my ($orig, $self, $path) = @_;
  my @input_path;

  if (ref $path) {
    @input_path = @$path;
  } else {
    Carp::confess("invalid path: empty") unless defined $path and length $path;

    @input_path = File::Spec::Unix->splitdir($path);
  }

  Carp::confess("invalid path: empty") unless @input_path;
  Carp::confess("invalid path: ends with non-filename")
    if $input_path[-1] eq '';

  my @return_path;
  push @return_path, (shift @input_path) if $input_path[0] eq '';
  push @return_path, grep { defined $_ and length $_ } @input_path;

  my $entity = $self->$orig(\@return_path);

  return unless defined $entity;

  if (my $conv = $self->converter) {
    return $conv->convert($entity);
  } else {
    my $native_type = $self->native_type;

    if (my $error = $native_type->validate($entity)) {
      confess $error;
    }

    return $entity;
  }
};

#pod =method native_type
#pod
#pod This method should return a L<Moose::Meta::TypeConstraint> indicating the type
#pod of entity that will be located by the resolver's native C<entity_at>.
#pod
#pod It must be provided by classes implementing the Path::Resolver::Role::Resolver
#pod role.
#pod
#pod =cut

requires 'native_type';

#pod =method effective_type
#pod
#pod This method returns the type that the wrapped C<entity_at> method will return.
#pod This means that if there is a converter (see below) it will return the
#pod converter's output type.  Otherwise, it will return the resolver's native type.
#pod
#pod =cut

sub effective_type {
  my ($self) = @_;
  return $self->native_type unless $self->converter;
  return $self->converter->output_type;
}

#pod =method converter
#pod
#pod The converter method (actually an attribute) may be undef or may be an object
#pod that implements the
#pod L<Path::Resolver::Role::Converter|Path::Resolver::Role::Converter> object.
#pod
#pod It will be used to convert objects from the resolver's native type to another
#pod type.
#pod
#pod =cut

has converter => (
  is      => 'ro',
  isa     => maybe_type( role_type('Path::Resolver::Role::Converter') ),
  builder => 'default_converter',
);

#pod =method default_converter
#pod
#pod This method can be implemented by resolver classes to set a default converter.
#pod The version provided by this role returns false.
#pod
#pod To see an example of this put to use, see
#pod L<Path::Resolver::Role::FileResolver>.
#pod
#pod =cut

sub default_converter { return }

#pod =method content_for
#pod
#pod   my $content_ref = $resolver->content_for($path);
#pod
#pod This method is provided with backward compatibility with previous versions of
#pod Path::Resolver.  B<This method will be removed in the near future.>
#pod
#pod It calls C<entity_at> and then calls the C<content_ref> on the entity.  If
#pod the entity doesn't provide a C<content_ref> method, an exception will be
#pod thrown.
#pod
#pod =cut

sub content_for {
  my ($self, $path) = @_;
  return unless my $entity = $self->entity_at($path);

  confess "located entity can't perform the content_ref method"
    unless $entity->can('content_ref');

  return $entity->content_ref;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Path::Resolver::Role::Resolver - resolving paths is just what resolvers do!

=head1 VERSION

version 3.100455

=head1 DESCRIPTION

A class that implements this role can be used to resolve paths into entities.
They declare the type of entity that they will produce internally, and may have
a mechanism for converting that entity into another type before returning it.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 entity_at

  my $entity = $resolver->entity_at($path);

This is the most important method in a resolver.  It is handed a unix-style
filepath and does one of three things:

=over

=item * returns an entity if a suitable one can be found

=item * returns undef if no entity can be found

=item * raises an exception if the entity found is unsuitable or if an error occurs

=back

Much of the logic of this method is implemented by an C<around> modifier
applied by the role.  This modifier will convert paths from strings into
arrayrefs of path parts.

Empty path parts are removed -- except for the first, which would represent the
root are skipped, and the last, which would imply that you provided a path
ending in /, which is a directory.

If the resolver has a C<converter> (see below) then the found entity will be
passed to the converter and the result will be returned.  Otherwise, the entity
will be type-checked and returned.

This means that to write a resolver, you must write a C<entity_at> method that
accepts an arrayref of path parts (strings) and returns an object of the type
indicated by the resolver's C<native_type> method (below).

=head2 native_type

This method should return a L<Moose::Meta::TypeConstraint> indicating the type
of entity that will be located by the resolver's native C<entity_at>.

It must be provided by classes implementing the Path::Resolver::Role::Resolver
role.

=head2 effective_type

This method returns the type that the wrapped C<entity_at> method will return.
This means that if there is a converter (see below) it will return the
converter's output type.  Otherwise, it will return the resolver's native type.

=head2 converter

The converter method (actually an attribute) may be undef or may be an object
that implements the
L<Path::Resolver::Role::Converter|Path::Resolver::Role::Converter> object.

It will be used to convert objects from the resolver's native type to another
type.

=head2 default_converter

This method can be implemented by resolver classes to set a default converter.
The version provided by this role returns false.

To see an example of this put to use, see
L<Path::Resolver::Role::FileResolver>.

=head2 content_for

  my $content_ref = $resolver->content_for($path);

This method is provided with backward compatibility with previous versions of
Path::Resolver.  B<This method will be removed in the near future.>

It calls C<entity_at> and then calls the C<content_ref> on the entity.  If
the entity doesn't provide a C<content_ref> method, an exception will be
thrown.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
