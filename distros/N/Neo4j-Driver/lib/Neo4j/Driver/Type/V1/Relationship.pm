use v5.12;
use warnings;

package Neo4j::Driver::Type::V1::Relationship 1.02;
# ABSTRACT: Describes a relationship from a Neo4j graph, delivered via Jolt v1 or JSON


# For documentation, see Neo4j::Driver::Types.


use parent 'Neo4j::Driver::Type::Relationship';


sub element_id {
	my ($self) = @_;
	
	warnings::warnif 'Neo4j::Types', 'element_id unavailable';
	return $self->[0];
}


sub start_element_id {
	my ($self) = @_;
	
	warnings::warnif 'Neo4j::Types', 'start_element_id unavailable';
	return $self->[1];
}


sub end_element_id {
	my ($self) = @_;
	
	warnings::warnif 'Neo4j::Types', 'end_element_id unavailable';
	return $self->[3];
}


sub id {
	my ($self) = @_;
	
	return $self->[0];
}


sub start_id {
	my ($self) = @_;
	
	return $self->[1];
}


sub end_id {
	my ($self) = @_;
	
	return $self->[3];
}


1;
