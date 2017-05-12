package Repository::Simple::Property;

use strict;
use warnings;

our $VERSION = '0.06';

use Readonly;
use Repository::Simple::Permission;
use Repository::Simple::Util qw( normalize_path );
use Repository::Simple::Value;

our @CARP_NOT = qw( Repository::Simple::Util );

=head1 NAME

Repository::Simple::Property - Repository properties

=head1 SYNOPSIS

See L<Repository::Simple::Node>.

=head1 DESCRIPTION

Each instance of this class represents a single property of a node.

To retrieve a property instance, do not construct the object directly. Rather, use the methods associated with a node to retrieve the properties associated with that node:

  my @properties = $node->properties;
  for my $property (@properties) {
      print $property->name, " = ", $property->value->get_scalar;
  }

Each property has a parent (node), a name, a value, and a type. The name is non-empty string identifying the property. The value is a valid value according to the property type. The type is an instance of L<Repository::Simple::Type::Property>. If a property value is set to C<undef>, this is the same as deleting the property from the parent node.

=cut

# $property = Repository::Simple::Property->new($node, $name)
#
# Create a new property object.
sub new {
    my ($class, $node, $name) = @_;
    return bless {
        node  => $node,
        name  => $name,
    }, $class;
}

=over

=item $node = $self-E<gt>parent

Get the node to which this property belongs.

=cut

sub parent {
    my $self = shift;
    return $self->{node};
}

=item $name = $self-E<gt>name

Get the name of the property.

=cut

sub name {
    my $self = shift;
    return $self->{name};
}

=item $path = $self-E<gt>path

Get the full path to the property.

=cut

sub path {
    my $self = shift;
    return $self->{path} if $self->{path};
    return $self->{path} = normalize_path($self->{node}->path, $self->{name});
}

=item $value = $self-E<gt>value

Retrieve the value stored in the property.

=cut

sub value {
    my $self = shift;
    return Repository::Simple::Value->new(
        $self->parent->repository, $self->path);
}

=item $type = $self-E<gt>type

Retrieve the L<Repository::Simple::Type::Property> used to validate and store values for this property.

=cut

sub type {
    my $self = shift;
    return $self->engine->property_type_of($self->path);
}

sub engine {
    my $self = shift;
    return $self->{engine} if $self->{engine};
    return $self->{engine} = $self->{node}->repository->engine;
}

=item $property-E<gt>save

Tells the storage engine to save the property. If you've modified the property
somehow, the change might already have been made. However, the change is not
guaranteed until this method is called.

=cut

sub save {
    my $self = shift;
    my $path = $self->path;
    $self->parent->repository->check_permission($path, $SET_PROPERTY);
    return $self->engine->save_property($path);
}

=back

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2005 Andrew Sterling Hanenkamp E<lt>hanenkamp@cpan.orgE<gt>.  All 
Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.

=cut

1
