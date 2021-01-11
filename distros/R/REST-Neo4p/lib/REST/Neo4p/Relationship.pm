#$Id$
package REST::Neo4p::Relationship;
use base 'REST::Neo4p::Entity';
use REST::Neo4p::Exceptions;
use Carp qw(croak carp);
use strict;
use warnings;
BEGIN {
  $REST::Neo4p::Relationship::VERSION = '0.4001';
}

sub new {
  my $self = shift;
  my ($from_node, $to_node, $type, $rel_props) = @_;
  unless (ref $from_node && $from_node->isa('REST::Neo4p::Node') &&
	  ref $to_node && $to_node->isa('REST::Neo4p::Node') &&
	  defined $type) {
    REST::Neo4p::LocalException->throw("Requires 2 REST::Neo4p::Node objects and a relationship type\n");
  }
  return $from_node->relate_to($to_node, $type, $rel_props);
}

sub type {
  my $self = shift;
  return $self->_entry->{type};
}

sub start_node {
  return REST::Neo4p->get_node_by_id(shift->_entry->{start_id});
}

sub end_node {
  return REST::Neo4p->get_node_by_id(shift->_entry->{end_id});
}

sub as_simple {
  my $self = shift;
  my $ret;
  my $props = $self->get_properties;
  $ret->{_relationship} = $$self + 0;
  $ret->{_type} = $self->type;
  $ret->{_start} = ${$self->start_node};
  $ret->{_end} = ${$self->end_node};
  $ret->{$_} = $props->{$_} for keys %$props;
  return $ret;
}

sub simple_from_json_response {
  my $class = shift;
  my ($decoded_resp) = @_;
  my $ret;
  for (ref $decoded_resp) {
    /HASH/ && do {
      # reln id
      ($ret->{_relationship}) = $decoded_resp->{self} =~ m{.*/([0-9]+)$};
      # reln type
      $ret->{_type} = $decoded_resp->{type};
      # reln properties
      $ret->{$_} = $decoded_resp->{data}->{$_} for keys %{$decoded_resp->{data}};
      # start and end nodes (by id)
      ($ret->{_start}) = $decoded_resp->{start} =~ m{.*/([0-9]+)$};
      ($ret->{_end}) = $decoded_resp->{end} =~ m{.*/([0-9]+)$};
      last;
    };
    /Driver/ && do {
      $ret->{_relationship} = $decoded_resp->id;
      $ret->{_type} = $decoded_resp->type;
      $ret->{$_} = $decoded_resp->properties->{$_} for keys %{$decoded_resp->properties};
      $ret->{_start} = $decoded_resp->start_id;
      $ret->{_end} = $decoded_resp->end_id;
      last;
    };
    do {
      die "?";
    };
  }
  return $ret;
}

=head1 NAME

REST::Neo4p::Relationship - Neo4j relationship object

=head1 SYNOPSIS

 $n1 = REST::Neo4p::Node->new( {name => 'Harry'} );
 $n2 = REST::Neo4p::Node->new( {name => 'Sally'} );
 $r1 = $n1->relate_to($n2, 'met');
 $r1->set_property({ when => 'July' });

 $r2 = REST::Neo4p::Relationship->new( $n2 => $n1, 'dropped' );

=head1 DESCRIPTION

REST::Neo4p::Relationship objects represent Neo4j relationships.

=head1 METHODS

=over

=item new()

 $r1 = REST::Neo4p::Relationship->new($node1, $node2, 'ingratiates');

Creates the relationship given by the scalar third argument between
the first argument and second argument, both C<REST::Neo4p::Node>
objects. An optional fourth argument is a hashref of I<relationship> 
properties.

=item remove()

 $reln->remove()

Removes the relationship from the database.

=item get_property()

 $status = $reln->get_property('status');

Get the values of properties on nodes and relationships.

=item set_property()

 $node1->relate_to($node2,"is_pal_of")->set_property( {duration => 'old pal'} );

Sets values of properties on nodes and relationships.

=item get_properties()

 $props = $relationship->get_properties;
 print "Come here often?" if ($props->{status} eq 'not_currently_seeing');

Get all the properties of relationship as a hashref.

=item remove_property()

 $relationship->remove_property('name');
 $relationship->remove_property(@property_names);

Remove properties from relationship.

=item start_node(), end_node()

 $fred_node = $married_to->start_node;
 $wilma_node = $married_to->end_node;

Get the start and end nodes of the relationship.

=item type()

 $rel = $node->relate_to($node2, 'my_type');
 print "This is my_type of relationship" if $rel->type eq 'my_type';

Gets a relationship's type.

=item Property auto-accessors

See L<REST::Neo4p/Property Auto-accessors>.

=item as_simple()

 $simple_reln = $reln1->as_simple
 $rel_id = $simple_reln->{_relationship};
 $value = $simple_reln->{$property_name};
 $type = $simple_reln->{_type};
 $start_node_id = $simple_reln->{_start};
 $end_node_id = $simple_reln->{_end};

Get relationship as a simple hashref.

=back

=head1 SEE ALSO

L<REST::Neo4p>, L<REST::Neo4p::Node>, L<REST::Neo4p::Index>.

=head1 AUTHOR

    Mark A. Jensen
    CPAN ID: MAJENSEN
    majensen -at- cpan -dot- org

=head1 LICENSE

Copyright (c) 2012-2021 Mark A. Jensen. This program is free software; you
can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

1;
