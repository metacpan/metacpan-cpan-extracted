use v5.10.1;
use strict;
use warnings;

package Neo4j::Types::Node;
# ABSTRACT: Represents a Neo4j node / graph vertex
$Neo4j::Types::Node::VERSION = '2.00';


sub get {
	my ($self, $property) = @_;
	
	return $self->{properties}->{$property};
}


sub id {
	my ($self) = @_;
	
	return $self->{id};
}


sub labels {
	my ($self) = @_;
	
	return my @empty unless defined $self->{labels};
	return @{$self->{labels}};
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
