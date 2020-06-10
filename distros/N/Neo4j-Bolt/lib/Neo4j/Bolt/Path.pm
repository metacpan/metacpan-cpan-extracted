package Neo4j::Bolt::Path;
# ABSTRACT: Representation of Neo4j Path

$Neo4j::Bolt::Path::VERSION = '0.20';

use strict;
use warnings;

sub as_simple {
  my ($self) = @_;
  
  return [ @$self ];
}

1;

__END__

=head1 NAME

Neo4j::Bolt::Path - Representation of a Neo4j Path

=head1 SYNOPSIS

 $q = 'MATCH p=(n1)-[r]->(n2) RETURN p';
 $path = ( $cxn->run_query($q)->fetch_next )[0];
 
 ($n1, $r, $n2) = @$path;
 
 @nodes         = grep { ref eq 'Neo4j::Bolt::Node' } @$path;
 @relationships = grep { ref eq 'Neo4j::Bolt::Relationship' } @$path;
 
 $start_node = $path->[0];
 $end_node   = $path->[@$path - 1];
 $length     = @$path >> 1;  # number of relationships
 
 $arrayref = $path->as_simple;

=head1 DESCRIPTION

L<Neo4j::Bolt::Path> instances are created by executing
a Cypher query that returns paths from a Neo4j database.
Their nodes, relationships and metadata can be accessed
as shown in the synopsis above.

If a query returns the same path twice, two separate
L<Neo4j::Bolt::Path> instances will be created.

=head1 METHODS

=over

=item as_simple()

 $simple  = $path->as_simple;

Get path as a simple arrayref in the style of L<REST::Neo4p>.

The simple arrayref is unblessed, but is otherwise an exact duplicate
of the L<Neo4j::Bolt::Path> instance.

=back

=head1 SEE ALSO

L<Neo4j::Bolt>

=head1 AUTHOR

 Arne Johannessen
 CPAN: AJNN

=head1 LICENSE

This software is Copyright (c) 2020 by Arne Johannessen.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
