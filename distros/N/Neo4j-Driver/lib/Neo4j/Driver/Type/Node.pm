use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Type::Node;
# ABSTRACT: Describes a node from a Neo4j graph
$Neo4j::Driver::Type::Node::VERSION = '0.21';

use parent 'Neo4j::Types::Node';
use overload '%{}' => \&_hash, fallback => 1;

use Carp qw(croak);


sub get {
	my ($self, $property) = @_;
	
	return $$self->{$property};
}


sub labels {
	my ($self) = @_;
	
	croak 'labels() in scalar context not supported' unless wantarray;
	return unless defined $$self->{_meta}->{labels};
	return @{ $$self->{_meta}->{labels} };
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
	my ($self) = @_;
	
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

Neo4j::Driver::Type::Node - Describes a node from a Neo4j graph

=head1 VERSION

version 0.21

=head1 SYNOPSIS

 $query = 'MATCH (m:Movie) RETURN m LIMIT 1';
 $node = $driver->session->run($query)->single->get('m');
 
 say 'Movie # ', $node->id(), ' :';
 say '   ', $node->get('name'), ' / ', $node->get('year');
 say '   Labels: ', join ', ', $node->labels;

=head1 DESCRIPTION

Describes a node from a Neo4j graph. A node may be a
part of L<records|Neo4j::Driver::Record> returned from Cypher
statement execution. Its description contains the node's
properties as well as certain meta data, all accessible by methods
that this class provides.

L<Neo4j::Driver::Type::Node> objects are not in a
one-to-one relation with nodes in a Neo4j graph. If the
same Neo4j node is fetched multiple times, then multiple
distinct L<Neo4j::Driver::Type::Node> objects will be
created by the driver. If your intention is to verify that two
L<Neo4j::Driver::Type::Node> objects in Perl describe the
same node in the Neo4j database, you need to compare their
IDs.

=head1 METHODS

L<Neo4j::Driver::Type::Node> inherits all methods from
L<Neo4j::Types::Node>.

=head2 get

 $value = $node->get('property_key');

See L<Neo4j::Types::Node/"get">.

=head2 id

 $id = $node->id;

See L<Neo4j::Types::Node/"id">.

=head2 labels

 @labels = $node->labels;

See L<Neo4j::Types::Node/"labels">.

=head2 properties

 $hashref = $node->properties;
 $value = $hashref->{property_key};

See L<Neo4j::Types::Node/"properties">.

=head1 EXPERIMENTAL FEATURES

L<Neo4j::Driver::Type::Node> implements the following experimental
features. These are subject to unannounced modification or removal
in future versions. Expect your code to break if you depend upon
these features.

=head2 Calling in scalar context

 $labels = $node->labels;  # fails

The C<labels()> method C<die>s if called in scalar context.

=head2 Deletion indicator

 $node_exists = ! $node->deleted;

In some circumstances, Cypher statements using C<DELETE> may still
C<RETURN> nodes that were deleted. To help avoid confusion in
such cases, the server sometimes reports whether or not a node
was deleted.

This method is experimental because that information is not reliably
available. In particular, there is a known issue with the Neo4j server
(L<#12306|https://github.com/neo4j/neo4j/issues/12306>), and old Neo4j
versions may not report it at all. If unavailable, C<undef> will be
returned by this method.

=head1 BUGS

The value of properties named C<_meta>, C<_node>, or C<_labels> may
not be returned correctly.

When using HTTP JSON, the C<labels> of nodes that are returned as
part of a L<Neo4j::Driver::Type::Path> are unavailable, because that
information is not currently reported by the Neo4j server. C<undef>
is returned instead.

=head1 SEE ALSO

=over

=item * L<Neo4j::Driver>

=item * L<Neo4j::Types::Node>

=item * Equivalent documentation for the official Neo4j drivers:
L<Node (Java)|https://neo4j.com/docs/api/java-driver/current/index.html?org/neo4j/driver/types/Node.html>,
L<Node (Python)|https://neo4j.com/docs/api/python-driver/current/api.html#node>

=back

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2021 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
