use strict;
use warnings;

package Neo4j::Types::Relationship;
# ABSTRACT: Describes a relationship from a Neo4j graph
$Neo4j::Types::Relationship::VERSION = '1.00';


sub get {
	my ($self, $property) = @_;
	
	return unless defined $self->{properties};
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


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Types::Relationship - Describes a relationship from a Neo4j graph

=head1 VERSION

version 1.00

=head1 SYNOPSIS

 $rel_id   = $relationship->id;
 $rel_type = $relationship->type;
 
 $start_node_id = $relationship->start_id;
 $end_node_id   = $relationship->end_id;
 
 $property1  = $relationship->get('property1');
 $property2  = $relationship->get('property2');
 %properties = %{ $relationship->properties };

=head1 DESCRIPTION

Describes a relationship from a Neo4j graph. A relationship may
be created by executing a Cypher statement against a Neo4j database
server. Its description contains the relationship's properties as
well as certain meta data, all accessible by methods that
this class provides.

This module makes no assumptions about its internal data
structure. While default implementations for all methods
are provided, inheritors are free to override these
according to their needs. The default implementations
assume the data is stored in the format defined for
L<Neo4j::Bolt::Relationship>.

L<Neo4j::Types::Relationship> objects are typically not in a
one-to-one relation with relationships in a Neo4j graph. If the
same Neo4j relationship is fetched multiple times, then multiple
distinct L<Neo4j::Types::Relationship> objects may be created.
Refer to the documentation of the Perl module you use to
fetch relationships from the Neo4j database for information about
how that particular module handles this aspect.

=head1 METHODS

L<Neo4j::Types::Relationship> implements the following methods.

=head2 get

 $value = $relationship->get('property_key');

Retrieve the value of this relationship's property with the given
key. If no such key exists, return an undefined value.

=head2 id

 $id = $relationship->id;

Return an ID for this relationship that is unique within
a particular context, for example the current
L<driver session|Neo4j::Driver::Session> or
L<Bolt connection|Neo4j::Bolt::Cxn>.

Neo4j relationship IDs are not designed to be persistent.
After a relationship is deleted, its ID may be reused by
another relationship.

IDs are always integer numbers.
A relationship with the ID C<0> may exist.
Nodes and relationships do not share the same ID space.

=head2 properties

 $hashref = $relationship->properties;
 $value = $hashref->{property_key};

Return all properties of this relationship as a hash reference.

=head2 start_id

 $id = $relationship->start_id;

Return an ID for the node where this relationship starts.

=head2 end_id

 $id = $relationship->end_id;

Return an ID for the node where this relationship ends.

=head2 type

 $type = $relationship->type;

Return the type of this relationship.

=head1 BUGS

The behaviour of the C<properties()> method when called
in list context has not yet been defined.

The effect of making changes to the contents of the hash
to which a reference is returned from the C<properties()>
method has not yet been defined.

=head1 SEE ALSO

=over

=item * L<Neo4j::Types::B<Node>>

=item * L<Neo4j::Bolt::Relationship>

=item * L<Neo4j::Driver::Type::Relationship>

=item * L<REST::Neo4p::Relationship>

=item * L<"Structural types" in Neo4j Cypher Manual|https://neo4j.com/docs/cypher-manual/current/syntax/values/#structural-types>

=back

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
