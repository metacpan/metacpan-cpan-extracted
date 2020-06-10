package Neo4j::Bolt::Relationship;
# ABSTRACT: Representation of Neo4j Relationship

$Neo4j::Bolt::Relationship::VERSION = '0.20';

use strict;
use warnings;

sub as_simple {
  my ($self) = @_;
  
  my %simple = defined $self->{properties} ? %{$self->{properties}} : ();
  $simple{_relationship} = $self->{id};
  $simple{_start} = $self->{start};
  $simple{_end} = $self->{end};
  $simple{_type} = $self->{type};
  return \%simple;
}

1;

__END__

=head1 NAME

Neo4j::Bolt::Relationship - Representation of a Neo4j Relationship

=head1 SYNOPSIS

 $q = 'MATCH ()-[r]-() RETURN r';
 $reln = ( $cxn->run_query($q)->fetch_next )[0];
 
 $reln_id       = $reln->{id};
 $reln_type     = $reln->{type};
 $start_node_id = $reln->{start};
 $end_node_id   = $reln->{end};
 $properties    = $reln->{properties} // {};
 %properties    = %$properties;
 
 $value1 = $reln->{properties}->{property1};
 $value2 = $reln->{properties}->{property2};
 
 $hashref = $reln->as_simple;

=head1 DESCRIPTION

L<Neo4j::Bolt::Relationship> instances are created by executing
a Cypher query that returns relationships from a Neo4j database.
Their properties and metadata can be accessed as shown in the
synopsis above.

If a query returns the same relationship twice, two separate
L<Neo4j::Bolt::Relationship> instances will be created.

=head1 METHODS

=over

=item as_simple()

 $simple = $reln->as_simple;
 
 $reln_id       = $simple->{_relationship};
 $reln_type     = $simple->{_type};
 $start_node_id = $simple->{_start};
 $end_node_id   = $simple->{_end};
 $value1        = $simple->{property1};
 $value2        = $simple->{property2};

Get relationship as a simple hashref in the style of L<REST::Neo4p>.

The value of properties named C<_relationship>, C<_type>, C<_start>
or C<_end> will be replaced with the relationship's metadata.

=back

=head1 SEE ALSO

L<Neo4j::Bolt>

=head1 AUTHOR

 Arne Johannessen
 CPAN: AJNN

=head1 LICENSE

This software is Copyright (c) 2020 by Arne Johannessen

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
