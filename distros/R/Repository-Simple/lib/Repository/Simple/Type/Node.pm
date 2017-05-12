package Repository::Simple::Type::Node;

use strict;
use warnings;

our $VERSION = '0.06';

use Carp;
use Repository::Simple::Util qw( dirname );
use Scalar::Util qw( weaken );

our @CARP_NOT = qw( Repository::Simple::Util );

=head1 NAME

Repository::Simple::Type::Node - Types for content repository nodes

=head1 SYNOPSIS

An example using this subroutine can be found in F<ex/print_types.pl> of the original source distribution.

  sub print_node_type {
      my $node = shift;
  
      my $type = $node->type;
  
      print $node->name, ' : ', $type->name;
      print ' [AC]' if $type->auto_created;
      print ' [UP]' if $type->updatable;
      print ' [RM]' if $type->removable;
      print "\n";
  
      my %property_types = $type->property_types;
      while (my ($name, $ptype_name) = each %property_types) {
          my $ptype = $node->repository->property_type($ptype_name);
  
          printf ' * %-10s : %-16s', $name, $ptype->name;
  
          print ' [AC]' if $ptype->auto_created;
          print ' [UP]' if $ptype->updatable;
          print ' [RM]' if $ptype->removable;
          print "\n";
      }
  }

=head1 DESCRIPTION

Node types are used to determine information about what kind of information is expected and required to be part of a node instance. A node type may also inherit features from one or more node types.

Most developers will not need to create node types, but may use node types to discover information about how a node can be manipulated and what kind of information can be expected from a given node.

=head2 METHODS

=over

=item $type = Repository::Simple::Type::Node-E<gt>new(%args)

Create a new node type with the given arguments, C<%args>.

The following arguments are used:

=over

=item engine (required)

This is the storage engine to which the node type belongs.

=item name (required)

This is the short identifying name for the type. This is should be a fully qualified name, e.g., "ns:name".

=item super_types

This option may be set to an array of node type names representing the node types that this node type inherits from. Only the possible/required child node types and property types are inheritable

If this option is not given, then the node type inherits nothing.

=item node_types

This option is set to a hash where the keys are node names and the values are either node type names or arrays of node type names. The string "*" is special for the keys, it means that a node of any name may be contained with the given type.

For example,

  node_types => {
      foo => 'my:typeX',
      bar => [ 'my:typeY', 'my:typeZ' ],
      '*' => [ 'my:typeX', 'my:typeZ' ],
  },

allows the nodes of the defined node type to have a child node named "foo" with type "my:typeX", a node named "bar" with either the type "my:typeY" or the type "my:typeZ", and any number of other nodes named anything with type "my:typeX" or "my:typeZ".

=item property_types

This option is set to a hash where the keys are property names and the values are either property type names or arrays of property type names.

=item auto_created

This option is set to true if this node will be created automatically when its parent is created.

By default, this value is false.

=item updatable

This is a property for all node types stating whether or not the node may be updated, i.e., renamed. This only affects the node itself and does not affect any of its properties or child nodes.

By default, this value is false.

=item removable

When this property is set to a true value, this node may not be removed from its parent node.

By default, this value is false.

=back

=cut

sub new {
    my $class = shift;
    my %args  = @_;

    if (!defined $args{engine}) {
        croak 'The "engine" argument must be given.';
    }

    weaken $args{engine};

    if (!defined $args{name}) {
        croak 'The "name" argument must be given.';
    }

    $args{super_types}     ||= [];

    $args{node_types}      ||= {};
    $args{property_types}  ||= {};

    $args{auto_created}    ||= 0;
    $args{updatable}       ||= 0;
    $args{removable}       ||= 0;

    return bless \%args, $class;
}

=item $name = $type-E<gt>name

This method returns the name of the type.

=cut

sub name {
    my $self = shift;
    return $self->{name};
}

=item @super_types = $type-E<gt>super_types

This method returns the direct super types of the type or an empty list if there are no direct super types.

=cut

sub super_types {
    my $self = shift;
    return @{ $self->{super_types} };
}

=item %node_types = $type-E<gt>node_types

Returns all the child nodes of this node type, including all nodes inherited from super_types. The keys of the returned nodes will be the node names. The values will be the names of the node type that node is expected to have.

=cut

sub node_types {
    my $self = shift;
    
    my %node_types;
    for my $super_type (@{ $self->{super_types} }) {
        %node_types = (
            %node_types, 
            $self->{engine}->node_type_named($super_type)->node_types
        );
    }

    %node_types = (%node_types, %{ $self->{node_types} });

    return %node_types;
}

=item %property_types = $type-E<gt>property_types

This method returns all properties that may be added to this node, including those inherited from super_types. The keys of the returned hash represent the names of those properties and the values represent the property types of those nodes.

=cut

sub property_types {
    my $self = shift;
    
    my %property_types;
    for my $supertype (@{ $self->{super_types} }) {
        %property_types = (
            %property_types, 
            $self->{engine}->node_type_named($supertype)->property_types
        );
    }

    %property_types = (%property_types, %{ $self->{property_types} });

    return %property_types;
}

=item $auto_created = $type-E<gt>auto_created

This method returns true if nodes of this type should be automatically created with their parent.

=cut

sub auto_created {
    my $self = shift;
    return $self->{auto_created};
}

=item $updatable = $type-E<gt>updatable

This method returns true if nodes of this type may be changed. A nodes mutability or immutability doesn't have any bearing on the mutability of child nodes or child properties.

=cut

sub updatable {
    my $self = shift;
    return $self->{updatable};
}

=item $removable = $type-E<gt>removable

This method returns true if nodes of this type may be removed from their parent.

=cut

sub removable {
    my $self = shift;
    return $self->{removable};
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
