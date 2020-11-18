#$Id$
package REST::Neo4p::Node;
use base 'REST::Neo4p::Entity';
use REST::Neo4p::Relationship;
use REST::Neo4p::Exceptions;
use JSON;
use Carp qw(croak carp);
use strict;
use warnings;
BEGIN {
  $REST::Neo4p::Node::VERSION = '0.4000';
}

# creation, deletion and property manipulation are delegated
# to the parent Entity.

# $node1->relate_to($node2, $relationship_type, \%reln_props);
# direction is from $node1 -> $node2
# return the Relationship object
sub relate_to {
  my $self = shift;
  my ($target_node, $rel_type, $rel_props) = @_;
  local $REST::Neo4p::HANDLE;
  REST::Neo4p->set_handle($self->_handle);
  my $agent = REST::Neo4p->agent;
  my $suffix = $self->_get_url_suffix('create_relationship')
    || 'relationships'; # weak workaround
  my $content = {
		 'to' => $target_node->_self_url,
		 'type' => $rel_type
		};
  if ($rel_props) {
    $content->{data} = $rel_props;
  }
  my $decoded_resp;
  eval {
    $decoded_resp = $agent->post_node([$$self,$suffix],
				      $content);
  };
  my $e;
  if ($e = Exception::Class->caught('REST::Neo4p::Exception')) {
    # TODO : handle different classes
    $e->rethrow;
  }
  elsif ($@) {
    ref $@ ? $@->rethrow : die $@;
  }
  return ref($decoded_resp) ? 
    REST::Neo4p::Relationship->new_from_json_response($decoded_resp) :
	REST::Neo4p::Relationship->new_from_batch_response($decoded_resp);
}

sub get_relationships {
  my $self = shift;
  my ($direction) = @_;
  $direction ||= 'all';
  local $REST::Neo4p::HANDLE;
  REST::Neo4p->set_handle($self->_handle);
  my $agent = REST::Neo4p->agent;
  my $action;
  for ($direction) {
    /^all$/ && do {
      $action = 'all_relationships';
      last;
    };
    /^in$/ && do {
      $action = 'incoming_relationships';
      last;
    };
    /^out$/ && do {
      $action = 'outgoing_relationships';
      last;
    };
    do { # huh?
      REST::Neo4p::LocalException->throw("Got '$direction' for relationship direction; expected [in|out|all]\n");
    };
  }
  my $decoded_resp;
  eval {
    my @a = split /\//,$self->_get_url_suffix($action);
    $decoded_resp = $agent->get_node($$self,@a);
  };
  my $e;
  if ($e = Exception::Class->caught('REST::Neo4p::Exception')) {
    # TODO : handle different classes
    $e->rethrow;
  }
  elsif ($@) {
    ref $@ ? $@->rethrow : die $@;
  }
  my @ret;
  # TODO: handle Neo4j::Driver case 
  if (ref $decoded_resp eq 'HASH') {
    $decoded_resp = [$decoded_resp];
  }
  for (@$decoded_resp) {
    push @ret, ref($_) ? 
      REST::Neo4p::Relationship->new_from_json_response($_) :
	  REST::Neo4p::Relationship->new_from_batch_response($_);
  }
  return @ret;
}

sub set_labels {
  my $self = shift;
  my @labels = @_;
  unless (REST::Neo4p->_check_version(2)) {
    REST::Neo4p::VersionMismatchException->throw("set_labels requires neo4j v2.0 or greater");
  }
  local $REST::Neo4p::HANDLE;
  REST::Neo4p->set_handle($self->_handle);
  my $agent = REST::Neo4p->agent;
  my $decoded_resp;
  eval {
    $decoded_resp= $agent->put_node([$$self,'labels'],[@labels]);
  };
  my $e;
  if ($e = Exception::Class->caught('REST::Neo4p::Exception')) {
    # TODO : handle different classes
    $e->rethrow;
  }
  elsif ($@) {
    ref $@ ? $@->rethrow : die $@;
  }
  return $self;
}

sub add_labels {
  my $self = shift;
  my @labels = @_;
  unless (REST::Neo4p->_check_version(2)) {
    REST::Neo4p::VersionMismatchException->throw("add_labels requires neo4j v2.0 or greater");
  }
  local $REST::Neo4p::HANDLE;
  REST::Neo4p->set_handle($self->_handle);
  my $agent = REST::Neo4p->agent;
  my $decoded_resp;
  eval {
    $decoded_resp= $agent->post_node([$$self,'labels'],[@labels]);
  };
  my $e;
  if ($e = Exception::Class->caught('REST::Neo4p::Exception')) {
    # TODO : handle different classes
    $e->rethrow;
  }
  elsif ($@) {
    ref $@ ? $@->rethrow : die $@;
  }
  return $self;
}

sub get_labels {
  my $self = shift;
  unless (REST::Neo4p->_check_version(2)) {
    REST::Neo4p::VersionMismatchException->throw("get_labels requires neo4j v2.0 or greater");
  }
  local $REST::Neo4p::HANDLE;
  REST::Neo4p->set_handle($self->_handle);
  my $agent = REST::Neo4p->agent;
  my $decoded_resp;
  eval {
    $decoded_resp = $agent->get_node($$self, 'labels');
  };
  my $e;
  if ($e = Exception::Class->caught('REST::Neo4p::Exception')) {
    # TODO : handle different classes
    $e->rethrow;
  }
  elsif ($@) {
    ref $@ ? $@->rethrow : die $@;
  }
  # TODO: handle Neo4j::Driver case
  return @$decoded_resp;
}

sub drop_labels {
  my $self = shift;
  unless (REST::Neo4p->_check_version(2)) {
    REST::Neo4p::VersionMismatchException->throw("drop_labels requires neo4j v2.0 or greater");
  }
  my @labels = @_;
  return $self unless @labels;
  local $REST::Neo4p::HANDLE;
  REST::Neo4p->set_handle($self->_handle);
  my $agent = REST::Neo4p->agent;
  my $decoded_resp;
  eval {
    foreach my $label (@labels) {
      $decoded_resp = $agent->delete_node($$self, 'labels', $label);
    }
  };
  my $e;
  if ($e = Exception::Class->caught('REST::Neo4p::Exception')) {
    # TODO : handle different classes
    $e->rethrow;
  }
  elsif ($@) {
    ref $@ ? $@->rethrow : die $@;
  }
  return $self;
}

sub get_incoming_relationships { shift->get_relationships('in',@_) }
sub get_outgoing_relationships { shift->get_relationships('out',@_) }
sub get_all_relationships { shift->get_relationships('all',@_) }

sub get_typed_relationships {
  my $self = shift;
  REST::Neo4p::NotImplException->throw( "get_typed_relationships() not implemented yet\n" );
}

sub as_simple {
  my $self = shift;
  my $ret;
  my $props = $self->get_properties;
  $ret->{_node} = $$self + 0;
  $ret->{$_} = $props->{$_} for keys %$props;
  return $ret;
}

sub simple_from_json_response {
  my $class = shift;
  my ($decoded_resp) = @_;
  my $ret;
  for (ref $decoded_resp) {
    /HASH/ && do {
      # node id
      ($ret->{_node}) = $decoded_resp->{self} =~ m{.*/([0-9]+)$};
      # node properties
      if ($decoded_resp->{data}) {
	$ret->{$_} = $decoded_resp->{data}->{$_} for keys %{$decoded_resp->{data}};
      }
      else { # use top-level keys except self
	$ret->{$_} = $decoded_resp->{$_} for grep !/^self$/, keys %{$decoded_resp};
      }
      last;
    };
    /Driver/ && do {
      $ret->{_node} = $decoded_resp->id;
      $ret->{$_} = $decoded_resp->properties->{$_} for keys %{$decoded_resp->properties};
      last;
    };
    do {
      die "?";
    };
  }
  return $ret;
}

=head1 NAME

REST::Neo4p::Node - Neo4j node object

=head1 SYNOPSIS

 $n1 = REST::Neo4p::Node->new( {name => 'Ferb'} )
 $n2 = REST::Neo4p::Node->new( {name => 'Phineas'} );
 $n3 = REST::Neo4p::Node->new( {name => 'Perry'} );
 $n1->relate_to($n2, 'brother');
 $n3->relate_to($n1, 'pet');
 $n3->set_property({ species => 'Ornithorhynchus anatinus' });

=head1 DESCRIPTION

REST::Neo4p::Node objects represent Neo4j nodes.

=head1 METHODS

=over

=item new()

 $node = REST::Neo4p::Node->new();
 $node_with_properties = REST::Neo4p::Node->new( \%props );

Instantiates a new Node object and creates corresponding node in the database.

=item remove()

 $node->remove()

B<CAUTION>: Removes a node from the database and destroys the object.

=item get_property()

 $name = $node->get_property('name');
 @vitals = $node->get_property( qw( height weight bp temp ) );

Get the values of properties on nodes and relationships.

=item set_property()

 $name = $node->set_property( {name => "Sun Tzu", occupation => "General"} );
 $node1->relate_to($node2,"is_pal_of")->set_property( {duration => 'old pal'} );

Sets values of properties on nodes and relationships.

=item get_properties()

 $props = $node->get_properties;
 print "'Sup, Al." if ($props->{name} eq 'Al');

Get all the properties of a node or relationship as a hashref.

=item remove_property()

 $node->remove_property('name');
 $node->remove_property(@property_names);

Remove properties from node.

=item relate_to()

 $relationship = $node1->relate_to($node2, 'manager', { matrixed => 'yes' });

Create a relationship between two nodes in the database and return the
L<REST::Neo4p::Relationship> object. Call on the "from" node, first
argument is the "to" node, second argument is the relationship type,
third optional argument is a hashref of I<relationship> properties.

=item get_relationships()

 @all_relationships = $node1->get_relationships()

Get all incoming and outgoing relationships of a node. Returns array
of L<REST::Neo4p::Relationship|REST::Neo4p::Relationship> objects;

=item get_incoming_relationships()

 @incoming_relationships = $node1->get_incoming_relationships();

=item get_outgoing_relationships()

 @outgoing_relationships = $node1->get_outgoing_relationships();

=item property auto-accessors

See L<REST::Neo4p/Property Auto-accessors>.

=item as_simple()

 $simple_node = $node1->as_simple
 $node_id = $simple_node->{_node};
 $value = $simple_node->{$property_name};

Get node as a simple hashref.

=back

=head2 METHODS - Neo4j Version 2.0+

These methods are supported by v2.0+ of the Neo4j server.

=over

=item set_labels()

 my $node = $node->set_labels($label1, $label2);

Sets the node's labels. This replaces any existing node labels.

=item add_labels()

 my $node = $node->add_labels($label3, $label4);

Add labels to the nodes existing labels.

=item get_labels()

 my @labels = $node->get_labels;

Retrieve the node's list of labels, if any.

=item drop_labels()

 my $node = $node->drop_labels($label1, $label4);

Remove one or more labels from a node.

=back

=head1 SEE ALSO

L<REST::Neo4p>, L<REST::Neo4p::Relationship>, L<REST::Neo4p::Index>.

=head1 AUTHOR

    Mark A. Jensen
    CPAN ID: MAJENSEN
    majensen -at- cpan -dot- org

=head1 LICENSE

Copyright (c) 2012-2020 Mark A. Jensen. This program is free software; you
can redistribute it and/or modify it under the same terms as Perl
itself.

=cut


1;
