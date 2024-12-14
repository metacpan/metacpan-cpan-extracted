use v5.12;
use warnings;

package Neo4j::Driver::Type::Node 1.02;
# ABSTRACT: Describes a node from a Neo4j graph


# For documentation, see Neo4j::Driver::Types.

# Jolt node: [ node_id, [node_labels], {properties} ]


use parent 'Neo4j::Types::Node';


sub get {
	my ($self, $property) = @_;
	
	return $self->[2]->{$property};
}


sub labels {
	my ($self) = @_;
	
	return @{ $self->[1] };
}


sub properties {
	my ($self) = @_;
	
	return $self->[2];
}


sub element_id {
	my ($self) = @_;
	
	return $self->[0];
}


sub id {
	my ($self) = @_;
	
	warnings::warnif deprecated => "Node->id() is deprecated since Neo4j 5; use element_id()";
	my ($id) = $self->[0] =~ m/^4:[^:]*:([0-9]+)/;
	$id = 0 + $id if defined $id;
	return $id;
}
# Unlike Bolt v5, the Jolt v2 format regrettably removes the legacy
# numeric ID from the response entirely. Therefore we generate it
# here using the algorithm from Neo4j's DefaultElementIdMapperV1;
# the final part of the element ID is identical to the legacy ID
# according to CypherFunctions in Neo4j 5.0-5.25.
# But this may break with future Neo4j versions.
# https://github.com/neo4j/neo4j/blob/5.25/community/values/src/main/java/org/neo4j/values/DefaultElementIdMapperV1.java#L61-L67
# https://github.com/neo4j/neo4j/blob/5.25/community/cypher/runtime-util/src/main/java/org/neo4j/cypher/operations/CypherFunctions.java#L1024-L1062
# https://community.neo4j.com/t/id-function-deprecated-how-to-replace-easily/62554/17


1;
