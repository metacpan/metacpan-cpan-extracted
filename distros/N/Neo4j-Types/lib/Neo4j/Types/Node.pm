use strict;
use warnings;

package Neo4j::Types::Node;
# ABSTRACT: Describes a node from a Neo4j graph
$Neo4j::Types::Node::VERSION = '1.00';

use Carp qw(croak);


sub get {
	my ($self, $property) = @_;
	
	return unless defined $self->{properties};
	return $self->{properties}->{$property};
}


sub id {
	my ($self) = @_;
	
	return $self->{id};
}


sub labels {
	my ($self) = @_;
	
	croak 'labels() in scalar context not supported' unless wantarray;
	return unless defined $self->{labels};
	return @{$self->{labels}};
}


sub properties {
	my ($self) = @_;
	
	return {} unless defined $self->{properties};
	return $self->{properties};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Types::Node - Describes a node from a Neo4j graph

=head1 VERSION

version 1.00

=head1 SYNOPSIS

 $node_id = $node->id;
 @labels  = $node->labels;
 
 $property1  = $node->get('property1');
 $property2  = $node->get('property2');
 %properties = %{ $node->properties };

=head1 DESCRIPTION

Describes a node from a Neo4j graph. A node may be created
by executing a Cypher statement against a Neo4j database
server. Its description contains the node's properties as
well as certain meta data, all accessible by methods that
this class provides.

This module makes no assumptions about its internal data
structure. While default implementations for all methods
are provided, inheritors are free to override these
according to their needs. The default implementations
assume the data is stored in the format defined for
L<Neo4j::Bolt::Node>.

L<Neo4j::Types::Node> objects are typically not in a
one-to-one relation with nodes in a Neo4j graph. If the
same Neo4j node is fetched multiple times, then multiple
distinct L<Neo4j::Types::Node> objects may be created.
Refer to the documentation of the Perl module you use to
fetch nodes from the Neo4j database for information about
how that particular module handles this aspect.

=head1 METHODS

L<Neo4j::Types::Node> implements the following methods.

=head2 get

 $value = $node->get('property_key');

Retrieve the value of this node's property with the given
key. If no such key exists, return an undefined value.

=head2 id

 $id = $node->id;

Return an ID for this node that is unique within
a particular context, for example the current
L<driver session|Neo4j::Driver::Session> or
L<Bolt connection|Neo4j::Bolt::Cxn>.

Neo4j node IDs are not designed to be persistent.
After a node is deleted, its ID may be reused by
another node.

IDs are always integer numbers.
A node with the ID C<0> may exist.
Nodes and relationships do not share the same ID space.

=head2 labels

 @labels = $node->labels;

Return all labels of this node.

=head2 properties

 $hashref = $node->properties;

Return all properties of this node as a hash reference.

=head1 BUGS

The behaviour of the C<labels()> method when called in
scalar context has not yet been defined.

The behaviour of the C<properties()> method when called
in list context has not yet been defined.

The effect of making changes to the contents of the hash
to which a reference is returned from the C<properties()>
method has not yet been defined.

=head1 SEE ALSO

=over

=item * L<Neo4j::Bolt::Node>

=item * L<Neo4j::Driver::Type::Node>

=item * L<REST::Neo4p::Node>

=item * L<"Structural types" in Neo4j Cypher Manual|https://neo4j.com/docs/cypher-manual/current/syntax/values/#structural-types>

=back

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
