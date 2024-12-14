use v5.12;
use warnings;

package Neo4j::Driver::Type::Relationship 1.02;
# ABSTRACT: Describes a relationship from a Neo4j graph


# For documentation, see Neo4j::Driver::Types.

# Jolt relationship: [ rel_id, start_node_id, rel_type, end_node_id, {properties} ]


use parent 'Neo4j::Types::Relationship';


sub get {
	my ($self, $property) = @_;
	
	return $self->[4]->{$property};
}


sub type {
	my ($self) = @_;
	
	return $self->[2];
}


sub start_element_id {
	my ($self) = @_;
	
	return $self->[1];
}


sub start_id {
	my ($self) = @_;
	
	warnings::warnif deprecated => "Relationship->start_id() is deprecated since Neo4j 5; use start_element_id()";
	my ($id) = $self->[1] =~ m/^4:[^:]*:([0-9]+)/;
	$id = 0 + $id if defined $id;
	return $id;
}


sub end_element_id {
	my ($self) = @_;
	
	return $self->[3];
}


sub end_id {
	my ($self) = @_;
	
	warnings::warnif deprecated => "Relationship->end_id() is deprecated since Neo4j 5; use end_element_id()";
	my ($id) = $self->[3] =~ m/^4:[^:]*:([0-9]+)/;
	$id = 0 + $id if defined $id;
	return $id;
}


sub properties {
	my ($self) = @_;
	
	return $self->[4];
}


sub element_id {
	my ($self) = @_;
	
	return $self->[0];
}


sub id {
	my ($self) = @_;
	
	warnings::warnif deprecated => "Relationship->id() is deprecated since Neo4j 5; use element_id()";
	my ($id) = $self->[0] =~ m/^5:[^:]*:([0-9]+)/;
	$id = 0 + $id if defined $id;
	return $id;
}
# see Node.pm for background on legacy ID parsing


1;
