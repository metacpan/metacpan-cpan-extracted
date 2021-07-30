use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Type::Relationship;
# ABSTRACT: Describes a relationship from a Neo4j graph
$Neo4j::Driver::Type::Relationship::VERSION = '0.26';

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


sub start_id {
	my ($self) = @_;
	
	return $$self->{_meta}->{start};
}


sub end_id {
	my ($self) = @_;
	
	return $$self->{_meta}->{end};
}


sub properties {
	my ($self) = @_;
	
	my $properties = { %$$self };
	delete $properties->{_meta};
	return $properties;
}


sub id {
	my ($self) = @_;
	
	return $$self->{_meta}->{id};
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

version 0.26

=head1 SYNOPSIS

 $q = "MATCH (a:Person)-[k:KNOWS]->(b:Person) RETURN k";
 $rel = $driver->session->run($q)->list->[0]->get('k');
 
 print 'Person # ', $rel->start_id;
 print ' ', $rel->type;
 print ' person # ', $rel->end_id;
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
IDs.

=head1 METHODS

L<Neo4j::Driver::Type::Relationship> inherits all methods from
L<Neo4j::Types::Relationship>.

=head2 get

 $value = $relationship->get('property_key');

See L<Neo4j::Types::Relationship/"get">.

=head2 id

 $id = $relationship->id;

See L<Neo4j::Types::Relationship/"id">.

=head2 properties

 $hashref = $relationship->properties;
 $value = $hashref->{property_key};

See L<Neo4j::Types::Relationship/"properties">.

=head2 start_id

 $id = $relationship->start_id;

See L<Neo4j::Types::Relationship/"start_id">.

=head2 end_id

 $id = $relationship->end_id;

See L<Neo4j::Types::Relationship/"end_id">.

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
L<Relationship (Java)|https://neo4j.com/docs/api/java-driver/current/index.html?org/neo4j/driver/types/Relationship.html>,
L<Relationship (Python)|https://neo4j.com/docs/api/python-driver/current/api.html#relationship>

=back

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2021 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
