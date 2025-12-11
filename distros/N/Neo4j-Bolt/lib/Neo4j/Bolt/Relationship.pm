package Neo4j::Bolt::Relationship;
# ABSTRACT: Representation of Neo4j Relationship

$Neo4j::Bolt::Relationship::VERSION = '0.5001';

use v5.12;
use warnings;

use parent 'Neo4j::Types::Relationship';

sub element_id {
  my $self = shift;
  if ($self->{element_id} eq $self->{id}) {
    warnings::warnif 'Neo4j::Types', 'element_id unavailable';
    return $self->{id};
  }
  return $self->{element_id};
}

sub start_element_id {
  my $self = shift;
  if ($self->{start_element_id} eq $self->{start}) {
    warnings::warnif 'Neo4j::Types', 'start_element_id unavailable';
    return $self->{start};
  }
  return $self->{start_element_id};
}

sub end_element_id {
  my $self = shift;
  if ($self->{end_element_id} eq $self->{end}) {
    warnings::warnif 'Neo4j::Types', 'end_element_id unavailable';
    return $self->{end};
  }
  return $self->{end_element_id};
}

sub id { shift->{id} }
sub start_id { shift->{start} }
sub end_id { shift->{end} }

sub type { shift->{type} }
sub properties { shift->{properties} // {} }

sub get {
  my $self = shift;
  my ($property) = @_;
  return $self->{properties}->{$property};
}

sub as_simple {
  my $self = shift;
  my %simple = defined $self->{properties} ? %{$self->{properties}} : ();
  $simple{_relationship} = $self->{id};
  $simple{_element_id} = $self->{element_id};
  $simple{_start} = $self->{start};
  $simple{_start_element_id} = $self->{start_element_id};
  $simple{_end} = $self->{end};
  $simple{_end_element_id} = $self->{end_element_id};
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
 $reln_eltid    = $reln->{element_id};
 $reln_type     = $reln->{type};
 $start_node_id = $reln->{start};
 $start_node_el = $reln->{start_element_id};
 $end_node_id   = $reln->{end};
 $end_node_el   = $reln->{end_element_id};
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

This class conforms to the L<Neo4j::Types::Relationship> API, which
offers an object-oriented interface to the relationship's
properties and metadata. This is entirely optional to use.

If a query returns the same relationship twice, two separate
L<Neo4j::Bolt::Relationship> instances will be created.

=head1 METHODS

This class provides the following methods defined by
L<Neo4j::Types::Relationship>:

=over

=item * L<B<element_id()>|Neo4j::Types::Relationship/"element_id">

=item * L<B<get()>|Neo4j::Types::Relationship/"get">

=item * L<B<id()>|Neo4j::Types::Relationship/"id">

=item * L<B<properties()>|Neo4j::Types::Relationship/"properties">

=item * L<B<start_element_id()>|Neo4j::Types::Relationship/"start_element_id">

=item * L<B<start_id()>|Neo4j::Types::Relationship/"start_id">

=item * L<B<end_element_id()>|Neo4j::Types::Relationship/"end_element_id">

=item * L<B<end_id()>|Neo4j::Types::Relationship/"end_id">

=item * L<B<type()>|Neo4j::Types::Relationship/"type">

=back

The following additional method is provided:

=over

=item as_simple()

 $simple = $reln->as_simple;
 
 $reln_id       = $simple->{_relationship};
 $reln_el       = $simple->{_element_id};
 $reln_type     = $simple->{_type};
 $start_node_id = $simple->{_start};
 $start_node_el = $simple->{_start_element_id};
 $end_node_id   = $simple->{_end};
 $end_node_el   = $simple->{_end_element_id};
 $value1        = $simple->{property1};
 $value2        = $simple->{property2};

Get relationship as a simple hashref in the style of L<REST::Neo4p>.

The value of properties named C<_relationship>, C<_element_id>,
C<_type>, C<_start>, C<_start_element_id>, C<_end>, or
C<_end_element_id> will be replaced with the relationship's metadata.

=back

=head1 SEE ALSO

L<Neo4j::Bolt>, L<Neo4j::Types::Relationship>

=head1 AUTHOR

 Arne Johannessen
 CPAN: AJNN

=head1 LICENSE

This software is Copyright (c) 2020-2024 by Arne Johannessen

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
