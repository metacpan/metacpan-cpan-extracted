use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Type::Relationship;
# ABSTRACT: Describes a relationship from a Neo4j graph
$Neo4j::Driver::Type::Relationship::VERSION = '0.33';

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
	return $$self->{_meta}->{start};
}


sub start_id {
	my ($self) = @_;
	
	return $$self->{_meta}->{start} if defined $$self->{_meta}->{start};
	my ($id) = $$self->{_meta}->{element_start} =~ m/^4:[^:]*:([0-9]+)/;
	$id = 0 + $id if defined $id;
	return $id;
}


sub end_element_id {
	my ($self) = @_;
	
	return $$self->{_meta}->{element_end} if defined $$self->{_meta}->{element_end};
	return $$self->{_meta}->{end};
}


sub end_id {
	my ($self) = @_;
	
	return $$self->{_meta}->{end} if defined $$self->{_meta}->{end};
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
	return $$self->{_meta}->{id};
}


sub id {
	my ($self) = @_;
	
	return $$self->{_meta}->{id} if defined $$self->{_meta}->{id};
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


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::Type::Relationship - Describes a relationship from a Neo4j graph

=head1 VERSION

version 0.33

=head1 SYNOPSIS

 $q = "MATCH (a:Person)-[k:KNOWS]->(b:Person) RETURN k";
 $rel = $driver->session->run($q)->list->[0]->get('k');
 
 print 'Person id ', $rel->start_element_id;
 print ' ', $rel->type;
 print ' person id ', $rel->end_element_id;
 print ' since ', $rel->properties->{since};

=head1 DESCRIPTION

Describes a relationship from a Neo4j graph. A relationship may be a
part of L<records|Neo4j::Driver::Record> returned from Cypher
statement execution. Its description contains the relationship's
properties as well as certain meta data, all accessible by methods
that this class provides.

L<Neo4j::Driver::Type::Relationship> objects are not in a
one-to-one relation with relationships in a Neo4j graph. If the
same Neo4j relationship is fetched multiple times, then multiple
distinct L<Neo4j::Driver::Type::Relationship> objects will be
created by the driver. If your intention is to verify that two
L<Neo4j::Driver::Type::Relationship> objects in Perl describe the
same node in the Neo4j database, you need to compare their
element IDs.

=head1 METHODS

L<Neo4j::Driver::Type::Relationship> inherits all methods from
L<Neo4j::Types::Relationship>.

=head2 element_id

 $string = $relationship->element_id;

Return an ID for this relationship that is unique within
a particular context, for example the current transaction.

This method provides the new element ID string introduced by
S<Neo4j 5>. If the element ID is unavailable, for example with
older Neo4j versions or with a L<Neo4j::Bolt> version that
hasn't yet been updated for S<Neo4j 5>, this method provides
the legacy numeric ID instead. Note that a numeric ID cannot
successfully be used with C<elementId()> in Cypher expressions.

Neo4j element IDs are not designed to be persistent. As such,
if you want a public identity to use for your relationships,
attaching an explicit 'id' property is a better choice.

=head2 get

 $value = $relationship->get('property_key');

See L<Neo4j::Types::Relationship/"get">.

=head2 id

 $number = $relationship->id;

Return a legacy numeric ID for this relationship that is unique
within a particular context, for example the current transaction.

Neo4j 5 has B<deprecated> numeric IDs. They will likely become
unavailable in future Neo4j versions. This method will try to
auto-generate a S<numeric ID> from the new S<element ID> value
(or return C<undef> if that fails). A deprecation warning will
be issued by this method in a future version of this driver.

Neo4j relationship IDs are not designed to be persistent. As such,
if you want a public identity to use for your relationships,
attaching an explicit 'id' property is a better choice.

Legacy IDs are always integer numbers.
A relationship with the ID C<0> may exist.
Nodes and relationships do not share the same ID space.

=head2 properties

 $hashref = $relationship->properties;
 $value = $hashref->{property_key};

See L<Neo4j::Types::Relationship/"properties">.

=head2 start_element_id

 $string = $relationship->start_element_id;

Return an element ID for the node where this relationship starts.

This method provides the new element ID string introduced by
S<Neo4j 5>. If the element ID is unavailable, for example with
older Neo4j versions or with a L<Neo4j::Bolt> version that
hasn't yet been updated for S<Neo4j 5>, this method provides
the legacy numeric ID instead.

=head2 start_id

 $number = $relationship->start_id;

Return a numeric ID for the node where this relationship starts.

Neo4j 5 has B<deprecated> numeric IDs. They will likely become
unavailable in future Neo4j versions. This method will try to
auto-generate a S<numeric ID> from the new S<element ID> value
(or return C<undef> if that fails). A deprecation warning will
be issued by this method in a future version of this driver.

=head2 end_element_id

 $string = $relationship->end_element_id;

Return an element ID for the node where this relationship ends.

This method provides the new element ID string introduced by
S<Neo4j 5>. If the element ID is unavailable, for example with
older Neo4j versions or with a L<Neo4j::Bolt> version that
hasn't yet been updated for S<Neo4j 5>, this method provides
the legacy numeric ID instead.

=head2 end_id

 $number = $relationship->end_id;

Return a numeric ID for the node where this relationship ends.

Neo4j 5 has B<deprecated> numeric IDs. They will likely become
unavailable in future Neo4j versions. This method will try to
auto-generate a S<numeric ID> from the new S<element ID> value
(or return C<undef> if that fails). A deprecation warning will
be issued by this method in a future version of this driver.

=head2 type

 $type = $relationship->type;

See L<Neo4j::Types::Relationship/"type">.

=head1 BUGS

The value of properties named C<_meta>, C<_relationship>, C<_start>,
C<_end>, or C<_type> may not be returned correctly.

When using HTTP JSON, the C<type> of relationships that are returned as
part of a L<Neo4j::Driver::Type::Path> is unavailable, because that
information is not currently reported by the Neo4j server. C<undef>
is returned instead.

=head1 SEE ALSO

=over

=item * L<Neo4j::Driver>

=item * L<Neo4j::Types::Relationship>

=item * Equivalent documentation for the official Neo4j drivers:
L<Relationship (Java)|https://neo4j.com/docs/api/java-driver/5.2/org.neo4j.driver/org/neo4j/driver/types/Relationship.html>,
L<Relationship (Python)|https://neo4j.com/docs/api/python-driver/5.2/api.html#relationship>

=back

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

If you contact me by email, please make sure you include the word
"Perl" in your subject header to help beat the spam filters.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2022 by Arne Johannessen.

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0 or (at your option) the same terms
as the Perl 5 programming language system itself.

=cut
