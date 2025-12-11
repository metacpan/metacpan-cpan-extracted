package Neo4j::Bolt::Node;
# ABSTRACT: Representation of Neo4j Node

$Neo4j::Bolt::Node::VERSION = '0.5001';

use v5.12;
use warnings;

use parent 'Neo4j::Types::Node';

sub element_id {
  my $self = shift;
  if ($self->{element_id} eq $self->{id}) {
    warnings::warnif 'Neo4j::Types', 'element_id unavailable';
    return $self->{id};
  }
  return $self->{element_id};
}

sub id { shift->{id} }

sub properties { shift->{properties} // {} }

sub get {
  my $self = shift;
  my ($property) = @_;
  return $self->{properties}->{$property};
}

sub labels {
  my $self = shift;
  return my @empty unless defined $self->{labels};
  return @{$self->{labels}};
}

sub as_simple {
  my $self = shift;
  my %simple = defined $self->{properties} ? %{$self->{properties}} : ();
  $simple{_node} = $self->{id};
  $simple{_element_id} = $self->{element_id};
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
 $node_eltid = $node->{element_id};
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

This class conforms to the L<Neo4j::Types::Node> API, which
offers an object-oriented interface to the node's
properties and metadata. This is entirely optional to use.

If a query returns the same node twice, two separate
L<Neo4j::Bolt::Node> instances will be created.

=head1 METHODS

This class provides the following methods defined by
L<Neo4j::Types::Node>:

=over

=item * L<B<element_id()>|Neo4j::Types::Node/"element_id">

=item * L<B<get()>|Neo4j::Types::Node/"get">

=item * L<B<id()>|Neo4j::Types::Node/"id">

=item * L<B<labels()>|Neo4j::Types::Node/"labels">

=item * L<B<properties()>|Neo4j::Types::Node/"properties">

=back

The following additional method is provided:

=over

=item as_simple()

 $simple  = $node->as_simple;
 
 $node_id = $simple->{_node};
 $eid     = $simple->{_element_id};
 @labels  = @{ $simple->{_labels} };
 $value1  = $simple->{property1};
 $value2  = $simple->{property2};

Get node as a simple hashref in the style of L<REST::Neo4p>.

The value of properties named C<_node>, C<_element_id>, or
C<_labels> will be replaced with the node's metadata.

=back

=head1 SEE ALSO

L<Neo4j::Bolt>, L<Neo4j::Types::Node>

=head1 AUTHOR

 Arne Johannessen
 CPAN: AJNN

=head1 LICENSE

This software is Copyright (c) 2019-2024 by Arne Johannessen.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
