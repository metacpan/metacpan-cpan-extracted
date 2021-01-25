use strict;
use warnings;

package Neo4j::Types::Path;
# ABSTRACT: Represents a directed sequence of relationships between two nodes
$Neo4j::Types::Path::VERSION = '1.00';

use Carp qw(croak);


sub elements {
	my ($self) = @_;
	
	croak 'elements() in scalar context not supported' unless wantarray;
	return @$self;
}


sub nodes {
	my ($self) = @_;
	
	croak 'nodes() in scalar context not supported' unless wantarray;
	my $i = 0;
	return grep { ++$i & 1 } @$self;
}


sub relationships {
	my ($self) = @_;
	
	croak 'relationships() in scalar context not supported' unless wantarray;
	my $i = 0;
	return grep { $i++ & 1 } @$self;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Types::Path - Represents a directed sequence of relationships between two nodes

=head1 VERSION

version 1.00

=head1 SYNOPSIS

 ($node1, $rel, $node2) = $path->elements;
 
 ($node1, $node2) = $path->nodes;
 ($rel)           = $path->relationships;

=head1 DESCRIPTION

A Neo4j path is a directed sequence of relationships between
two nodes. Its direction may be separate from that of the
relationships traversed.

It is allowed to have zero length, meaning there are no
relationships in it. In this case, it contains only a single
node which is both the start and the end of the path.

L<Neo4j::Types::Path> objects may be created by executing
a Cypher statement against a Neo4j database server.

This module makes no assumptions about its internal data
structure. While default implementations for all methods
are provided, inheritors are free to override these
according to their needs. The default implementations
assume the data is stored in the format defined for
L<Neo4j::Bolt::Path>.

=head1 METHODS

L<Neo4j::Types::Path> implements the following methods.

=head2 elements

 @all = $path->elements;

Return the path as a list alternating between nodes
and relationships in path sequence order.

=head2 nodes

 @nodes = $path->nodes;

Return all L<nodes|Neo4j::Types::Node> of this path.

The start node of this path is the first node in the list this method
returns, the end node is the last one.

 @nodes = $path->nodes;
 $start_node = $nodes[0];
 $end_node   = $nodes[@nodes - 1];

=head2 relationships

 @rels = $path->relationships;

Return all L<relationships|Neo4j::Types::Relationship>
of this path.

The length of a path is defined as the number of relationships.

 @rels = $path->relationships;
 $length = scalar @rels;

=head1 BUGS

The behaviour of the C<elements()>, C<nodes()> and
C<relationships()> methods when called in scalar context
has not yet been defined.

=head1 SEE ALSO

=over

=item * L<Neo4j::Types::B<Node>>, L<Neo4j::Types::B<Relationship>>

=item * L<Neo4j::Bolt::Path>

=item * L<Neo4j::Driver::Type::Path>

=item * L<REST::Neo4p::Path>

=item * L<"Structural types" in Neo4j Cypher Manual|https://neo4j.com/docs/cypher-manual/current/syntax/values/#structural-types>

=back

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
