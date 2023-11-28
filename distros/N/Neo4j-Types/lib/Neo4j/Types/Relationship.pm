use v5.10.1;
use strict;
use warnings;

package Neo4j::Types::Relationship;
# ABSTRACT: Represents a Neo4j relationship / graph edge
$Neo4j::Types::Relationship::VERSION = '2.00';


sub get {
	my ($self, $property) = @_;
	
	return $self->{properties}->{$property};
}


sub id {
	my ($self) = @_;
	
	return $self->{id};
}


sub type {
	my ($self) = @_;
	
	return $self->{type};
}


sub start_id {
	my ($self) = @_;
	
	return $self->{start};
}


sub end_id {
	my ($self) = @_;
	
	return $self->{end};
}


sub properties {
	my ($self) = @_;
	
	return {} unless defined $self->{properties};
	return $self->{properties};
}


# Workaround for warnings::register_categories() being unavailable
# in Perl v5.12 and earlier
package # private
        Neo4j::Types;
use warnings::register;


1;
