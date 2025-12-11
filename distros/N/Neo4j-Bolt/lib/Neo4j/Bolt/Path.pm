package Neo4j::Bolt::Path;
# ABSTRACT: Representation of Neo4j Path

$Neo4j::Bolt::Path::VERSION = '0.5001';

use v5.12;
use warnings;

use parent 'Neo4j::Types::Path';

sub elements {
  my $self = shift;
  return @$self;
}

sub nodes {
  my $self = shift;
  my $i = 0;
  return grep { ++$i & 1 } @$self;
}

sub relationships {
  my $self = shift;
  my $i = 0;
  return grep { $i++ & 1 } @$self;
}

sub as_simple {
  my $self = shift;
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

This class conforms to the L<Neo4j::Types::Path> API, which
offers an object-oriented interface to the paths's
elements and metadata. This is entirely optional to use.

If a query returns the same path twice, two separate
L<Neo4j::Bolt::Path> instances will be created.

=head1 METHODS

This class provides the following methods defined by
L<Neo4j::Types::Path>:

=over

=item * L<B<elements()>|Neo4j::Types::Path/"elements">

=item * L<B<nodes()>|Neo4j::Types::Path/"nodes">

=item * L<B<relationships()>|Neo4j::Types::Path/"relationships">

=back

The following additional method is provided:

=over

=item as_simple()

 $simple  = $path->as_simple;

Get path as a simple arrayref in the style of L<REST::Neo4p>.

The simple arrayref is unblessed, but is otherwise an exact duplicate
of the L<Neo4j::Bolt::Path> instance.

=back

=head1 SEE ALSO

L<Neo4j::Bolt>, L<Neo4j::Types::Path>

=head1 AUTHOR

 Arne Johannessen
 CPAN: AJNN

=head1 LICENSE

This software is Copyright (c) 2020-2024 by Arne Johannessen.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
