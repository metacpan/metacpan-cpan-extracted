use v5.12;
use warnings;

package Neo4j::Driver::Type::V1::Node 1.02;
# ABSTRACT: Describes a node from a Neo4j graph, delivered via Jolt v1 or JSON


# For documentation, see Neo4j::Driver::Types.


use parent 'Neo4j::Driver::Type::Node';


sub element_id {
	my ($self) = @_;
	
	warnings::warnif 'Neo4j::Types', 'element_id unavailable';
	return $self->[0];
}


sub id {
	my ($self) = @_;
	
	return $self->[0];
}


1;
