use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Type::Relationship;
# ABSTRACT: Describes a relationship from a Neo4j graph
$Neo4j::Driver::Type::Relationship::VERSION = '0.45';

# For documentation, see Neo4j::Driver::Types.


use parent 'Neo4j::Types::Relationship';
use overload '%{}' => \&_hash, fallback => 1;


sub get {
	my ($self, $property) = @_;
	
	return $$self->{$property};
}


sub type {
	my ($self) = @_;
	
	return $$self->{_meta}->{type};
}


sub start_element_id {
	my ($self) = @_;
	
	return $$self->{_meta}->{element_start} if defined $$self->{_meta}->{element_start};
	warnings::warnif 'Neo4j::Types', 'start_element_id unavailable';
	return $$self->{_meta}->{start};
}


sub start_id {
	my ($self) = @_;
	
	return $$self->{_meta}->{start} if defined $$self->{_meta}->{start};
	
	warnings::warnif deprecated => "Relationship->start_id() is deprecated since Neo4j 5; use start_element_id()";
	my ($id) = $$self->{_meta}->{element_start} =~ m/^4:[^:]*:([0-9]+)/;
	$id = 0 + $id if defined $id;
	return $id;
}


sub end_element_id {
	my ($self) = @_;
	
	return $$self->{_meta}->{element_end} if defined $$self->{_meta}->{element_end};
	warnings::warnif 'Neo4j::Types', 'end_element_id unavailable';
	return $$self->{_meta}->{end};
}


sub end_id {
	my ($self) = @_;
	
	return $$self->{_meta}->{end} if defined $$self->{_meta}->{end};
	
	warnings::warnif deprecated => "Relationship->end_id() is deprecated since Neo4j 5; use end_element_id()";
	my ($id) = $$self->{_meta}->{element_end} =~ m/^4:[^:]*:([0-9]+)/;
	$id = 0 + $id if defined $id;
	return $id;
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
	warnings::warnif 'Neo4j::Types', 'element_id unavailable';
	return $$self->{_meta}->{id};
}


sub id {
	my ($self) = @_;
	
	return $$self->{_meta}->{id} if defined $$self->{_meta}->{id};
	
	warnings::warnif deprecated => "Relationship->id() is deprecated since Neo4j 5; use element_id()";
	my ($id) = $$self->{_meta}->{element_id} =~ m/^5:[^:]*:([0-9]+)/;
	$id = 0 + $id if defined $id;
	return $id;
}


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


# As long as we remain compatible with Neo4j::Types 1.00,
# we need to register the warning category explicitly.
package # private
        Neo4j::Types;
use warnings::register;


1;
