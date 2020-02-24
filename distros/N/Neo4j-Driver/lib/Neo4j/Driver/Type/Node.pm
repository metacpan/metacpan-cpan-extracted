use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Type::Node;
# ABSTRACT: Describes a node from a Neo4j graph
$Neo4j::Driver::Type::Node::VERSION = '0.15';

use Carp qw(croak);


sub get {
	my ($self, $property) = @_;
	
	return $self->{$property};
}


sub labels {
	my ($self) = @_;
	
	croak 'labels() in scalar context not supported' unless wantarray;
	return @{ $self->{_meta}->{labels} };
}


sub properties {
	my ($self) = @_;
	
	my $properties = { %$self };
	delete $properties->{_meta};
	return $properties;
}


sub id {
	my ($self) = @_;
	
	return $self->{_meta}->{id};
}


sub deleted {
	my ($self) = @_;
	
	return $self->{_meta}->{deleted};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::Type::Node - Describes a node from a Neo4j graph

=head1 VERSION

version 0.15

=head1 SYNOPSIS

 $query = 'MATCH (m:Movie) RETURN m LIMIT 1';
 $node = $driver->session->run($query)->single->get('m');
 
 say 'Movie # ', $node->id(), ' :';
 say '   ', $node->get('name'), ' / ', $node->get('year');
 say '   Labels: ', join ', ', $node->labels;

=head1 DESCRIPTION

Describes a node from a Neo4j graph. A node may be a
part of L<records|Neo4j::Driver::Record> returned from Cypher
statement execution. Its description contains the node's
properties as well as certain meta data, all accessible by methods
that this class provides.

L<Neo4j::Driver::Type::Node> objects are not in a
one-to-one relation with nodes in a Neo4j graph. If the
same Neo4j node is fetched multiple times, then multiple
distinct L<Neo4j::Driver::Type::Node> objects will be
created by the driver. If your intention is to verify that two
L<Neo4j::Driver::Type::Node> objects in Perl describe the
same node in the Neo4j database, you need to compare their
IDs.

=head1 METHODS

L<Neo4j::Driver::Type::Node> implements the following methods.

=head2 get

 $value = $node->get('property_key');

Retrieve the value of this node's property with the given key.
If no such key exists, return C<undef>.

=head2 id

 $id = $node->id;

Return a unique ID for this node.

In the Neo4j Driver API, entity IDs are only guaranteed to remain
stable for the duration of the current session. Although in practice
server versions at least up to and including Neo4j 3.5 may appear
to use persistent IDs, your code should not depend upon that.

A node with the ID C<0> may exist.
Nodes and relationships do not share the same ID space.

=head2 labels

 @labels = $node->labels;

Return all labels of this node.

=head2 properties

 $hashref = $node->properties;
 $value = $hashref->{property_key};

Return all properties of this node as a hash reference.

=head1 EXPERIMENTAL FEATURES

L<Neo4j::Driver::Type::Node> implements the following experimental
features. These are subject to unannounced modification or removal
in future versions. Expect your code to break if you depend upon
these features.

=head2 Calling in scalar context

 $labels = $node->labels;  # fails

The C<labels()> method C<die>s if called in scalar context.

=head2 Direct data structure access

 $property_value = $node->{property_key};

Currently, the node's properties may be directly accessed as
if the node was a simple hashref. This is a concession to
backwards compatibility, as the data structure only started being
blessed as an object in version 0.13.

Relying on this implementation detail is deprecated.
Use the accessor methods C<get()> and C<properties()> instead.

=head2 Deletion indicator

 $node_exists = ! $node->deleted;

In some circumstances, Cypher statements using C<DELETE> may still
C<RETURN> nodes that were deleted. To help avoid confusion in
such cases, the server sometimes reports whether or not a node
was deleted.

This method is experimental because that information is not reliably
available. In particular, there is a known issue with the Neo4j server
(L<#12306|https://github.com/neo4j/neo4j/issues/12306>), and old Neo4j
versions may not report it at all. If unavailable, C<undef> will be
returned by this method.

=head1 BUGS

The value of properties named C<_meta>, C<_node>, or C<_labels> may
not be returned correctly.

When using HTTP, the C<labels> of nodes that are returned as
part of a L<Neo4j::Driver::Type::Path> are unavailable, because that
information is not currently reported by the Neo4j server. C<undef>
is returned instead.

=head1 SEE ALSO

=over

=item * L<Neo4j::Driver>

=item * Equivalent documentation for the official Neo4j drivers:
L<Node (Java)|https://neo4j.com/docs/api/java-driver/current/index.html?org/neo4j/driver/types/Node.html>,
L<Node (Python)|https://neo4j.com/docs/api/python-driver/current/types/graph.html#neo4j.types.graph.Node>

=back

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2020 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
