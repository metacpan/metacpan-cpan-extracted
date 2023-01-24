use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Type::Node;
# ABSTRACT: Describes a node from a Neo4j graph
$Neo4j::Driver::Type::Node::VERSION = '0.35';

use parent 'Neo4j::Types::Node';
use overload '%{}' => \&_hash, fallback => 1;

use Carp qw(croak);


sub get {
	my ($self, $property) = @_;
	
	return $$self->{$property};
}


sub labels {
	my ($self) = @_;
	
	$$self->{_meta}->{labels} //= [];
	return @{ $$self->{_meta}->{labels} };
}


sub properties {
	my ($self) = @_;
	
	my $properties = { %$$self };
	delete $properties->{_meta};
	return $properties;
}


sub element_id {
	my ($self) = @_;
	
	return $$self->{_meta}->{element_id} if defined $$self->{_meta}->{element_id};
	return $$self->{_meta}->{id};
}


sub id {
	my ($self) = @_;
	
	return $$self->{_meta}->{id} if defined $$self->{_meta}->{id};
	my ($id) = $$self->{_meta}->{element_id} =~ m/^4:[^:]*:([0-9]+)/;
	$id = 0 + $id if defined $id;
	return $id;
}
# Unlike Bolt v5, the Jolt v2 format regrettably removes the legacy
# numeric ID from the response entirely. Therefore we generate it
# here using the algorithm from Neo4j's DefaultElementIdMapperV1;
# the final part of the element ID is identical to the legacy ID
# according to CypherFunctions in Neo4j 5.3. This may break with
# future Neo4j versions.
# https://github.com/neo4j/neo4j/blob/0c092b70cc/community/kernel/src/main/java/org/neo4j/kernel/api/DefaultElementIdMapperV1.java#L62-L68
# https://github.com/neo4j/neo4j/blob/0c092b70cc/community/cypher/runtime-util/src/main/java/org/neo4j/cypher/operations/CypherFunctions.java#L771-L802


sub deleted {
	# uncoverable pod
	my ($self) = @_;
	
	warnings::warnif deprecated => __PACKAGE__ . "->deleted() is deprecated";
	return $$self->{_meta}->{deleted};
}


sub _hash {
	my ($self) = @_;
	
	warnings::warnif deprecated => "Direct hash access is deprecated; use " . __PACKAGE__ . "->properties()";
	return $$self;
}


# for experimental Cypher type system customisation only
sub _private {
	my ($self) = @_;
	
	return $$self;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::Type::Node - Describes a node from a Neo4j graph

=head1 VERSION

version 0.35

=head1 SYNOPSIS

 $query = 'MATCH (m:Movie) RETURN m LIMIT 1';
 $node = $driver->session->run($query)->single->get('m');
 
 say 'Movie id ', $node->element_id(), ' :';
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
element IDs.

=head1 METHODS

L<Neo4j::Driver::Type::Node> inherits all methods from
L<Neo4j::Types::Node>.

=head2 element_id

 $string = $node->element_id;

Return an ID for this node that is unique within
a particular context, for example the current transaction.

This method provides the new element ID string introduced by
S<Neo4j 5>. If the element ID is unavailable, for example with
older Neo4j versions or with a L<Neo4j::Bolt> version that
hasn't yet been updated for S<Neo4j 5>, this method provides
the legacy numeric ID instead. Note that a numeric ID cannot
successfully be used with C<elementId()> in Cypher expressions.

Neo4j element IDs are not designed to be persistent. As such,
if you want a public identity to use for your nodes,
attaching an explicit 'id' property is a better choice.

=head2 get

 $value = $node->get('property_key');

See L<Neo4j::Types::Node/"get">.

=head2 id

 $number = $node->id;

Return a legacy numeric ID for this node that is unique
within a particular context, for example the current transaction.

Neo4j 5 has B<deprecated> numeric IDs. They will likely become
unavailable in future Neo4j versions. This method will try to
auto-generate a S<numeric ID> from the new S<element ID> value
(or return C<undef> if that fails). A deprecation warning will
be issued by this method in a future version of this driver.

Neo4j node IDs are not designed to be persistent. As such,
if you want a public identity to use for your nodes,
attaching an explicit 'id' property is a better choice.

Legacy IDs are always integer numbers.
A node with the ID C<0> may exist.
Nodes and relationships do not share the same ID space.

=head2 labels

 @labels = $node->labels;

See L<Neo4j::Types::Node/"labels">.

=head2 properties

 $hashref = $node->properties;
 $value = $hashref->{property_key};

See L<Neo4j::Types::Node/"properties">.

=head1 EXPERIMENTAL FEATURES

L<Neo4j::Driver::Type::Node> implements the following experimental
features. These are subject to unannounced modification or removal
in future versions. Expect your code to break if you depend upon
these features.

=head2 Calling in scalar context

 $count = $node->labels;

The C<labels()> method returns the number of labels if called
in scalar context.

Until version 0.25, it C<die>d instead.

=head1 BUGS

The value of properties named C<_meta>, C<_node>, or C<_labels> may
not be returned correctly.

When using HTTP JSON, the C<labels> of nodes that are returned as
part of a L<Neo4j::Driver::Type::Path> are unavailable, because that
information is not currently reported by the Neo4j server. C<undef>
is returned instead.

=head1 SEE ALSO

=over

=item * L<Neo4j::Driver>

=item * L<Neo4j::Types::Node>

=item * Equivalent documentation for the official Neo4j drivers:
L<Node (Java)|https://neo4j.com/docs/api/java-driver/5.2/org.neo4j.driver/org/neo4j/driver/types/Node.html>,
L<Node (Python)|https://neo4j.com/docs/api/python-driver/5.2/api.html#node>

=back

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

If you contact me by email, please make sure you include the word
"Perl" in your subject header to help beat the spam filters.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2023 by Arne Johannessen.

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.

=cut
