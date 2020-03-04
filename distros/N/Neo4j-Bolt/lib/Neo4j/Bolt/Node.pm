package Neo4j::Bolt::Node;
# ABSTRACT: Representation of Neo4j Node

$Neo4j::Bolt::Node::VERSION = '0.12';

use strict;
use warnings;

sub as_simple {
  my ($self) = @_;
  
  my %simple = defined $self->{properties} ? %{$self->{properties}} : ();
  $simple{_node} = $self->{id};
  $simple{_labels} = defined $self->{labels} ? $self->{labels} : [];
  return \%simple;
}

1;

__END__

=head1 NAME

Neo4j::Bolt::Node - Representation of a Neo4j Node

=head1 SYNOPSIS

 $q = 'MATCH (n) RETURN n';
 $node = ( $cxn->run_query($q)->fetch_next )[0];
 
 $node_id    = $node->{id};
 $labels     = $node->{labels} // [];
 @labels     = @$labels;
 $properties = $node->{properties} // {};
 %properties = %$properties;
 
 $value1 = $node->{properties}->{property1};
 $value2 = $node->{properties}->{property2};
 
 $hashref = $node->as_simple;

=head1 DESCRIPTION

L<Neo4j::Bolt::Node> instances are created by executing
a Cypher query that returns nodes from a Neo4j database.
Their properties and metadata can be accessed as shown in the
synopsis above.

If a query returns the same node twice, two separate
L<Neo4j::Bolt::Node> instances will be created.

=head1 METHODS

=over

=item as_simple()

 $simple  = $node->as_simple;
 
 $node_id = $simple->{_node};
 @labels  = @{ $simple->{_labels} };
 $value1  = $simple->{property1};
 $value2  = $simple->{property2};

Get node as a simple hashref in the style of L<REST::Neo4p>.

The value of properties named C<_node> or C<_labels> will be
replaced with the node's metadata.

=back

=head1 SEE ALSO

L<Neo4j::Bolt>

=head1 AUTHOR

 Arne Johannessen
 CPAN: AJNN

=head1 LICENSE

This software is Copyright (c) 2019-2020 by Arne Johannessen.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
