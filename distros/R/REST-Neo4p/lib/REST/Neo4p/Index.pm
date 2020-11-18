#$Id$#
package REST::Neo4p::Index;
use base 'REST::Neo4p::Entity';
use REST::Neo4p::Exceptions;
use Carp qw(croak carp);
use URI::Escape;
use strict;
use warnings;

BEGIN {
  $REST::Neo4p::Index::VERSION = '0.4000';
}

my $unsafe = "^A-Za-z0-9\-\._\ ~";

# TODO: auto index objects ready-made

# new( 'node|relationship', $index_name )

sub new {
  my $class = shift;
  my ($index_type, $name, $config) = @_;
  # $config is for configuring an index (fulltext lucene e.g.)
  if (grep /^$name$/,qw(node relationship)) {
    my $a = $name;
    $name = $index_type;
    $index_type = $a;
  }
  unless (grep /^$index_type$/,qw(node relationship)) {
    REST::Neo4p::LocalException->throw("Index type must be either node or relationship\n");
  }
  my $properties = {
		    _addl_components => [$index_type],
		    name => $name
		   };
  $properties->{type} = delete $config->{rtype};
  $properties->{config} = $config if defined $config;
  my $idx;
  eval {
    $idx = $class->_entity_by_id($name,$index_type);
  };
  return $idx if $idx;
  return $class->SUPER::new($properties);
}

sub new_from_json_response {
  my $class = shift;
  my ($decoded_resp) = @_;
  my $obj = $class->SUPER::new_from_json_response($decoded_resp);
  $obj->_entry->{action} = $obj->_entry->{type}."_index";
  return $obj;
}

sub new_from_batch_response {
  my $class = shift;
  my ($id_token,$type) = @_;
  my $obj = $class->SUPER::new_from_batch_response($id_token);
  $obj->_entry->{type} = $type;  
  $obj->_entry->{action} = "${type}_index";
  return $obj;
}

sub remove {
  my $self = shift;
  $self->SUPER::remove($self->type);
}

# add an entity to an index
# add_entry($node, 'rating' => 'best')
# add_entry($node, %hash_of_entries)

sub add_entry {
  my $self = shift;
  my ($entity, @entry_hash) = @_;
  unless ($self->type eq $entity->entity_type) {
    REST::Neo4p::LocalException->throw(
      "Can't add a ".$entity->entity_type." to a ".$self->type." index\n"
     );
  }
  unless (@entry_hash && 
	    ((ref $entry_hash[0] eq 'HASH') || !(@entry_hash % 2))) {
    REST::Neo4p::LocalException->throw("A hash of key => value pairs is required\n");
  }
  my %entry_hash = (ref $entry_hash[0] eq 'HASH') ? 
		      %{$entry_hash[0]} : @entry_hash;
  local $REST::Neo4p::HANDLE;
  REST::Neo4p->set_handle($self->_handle);
  my $agent = REST::Neo4p->agent;
  my $rq = "post_".$self->_action;
  my $decoded_resp;
  while (my ($key, $value) = each %entry_hash) {
    eval {
      $decoded_resp = $agent->$rq([$self->name], 
				  { uri => $entity->_self_url,
				    key => $key,
				    value => uri_escape($value,$unsafe) }
				 );
    };
    if (my $e = REST::Neo4p::Exception->caught()) {
      # TODO : handle different classes?
      $e->rethrow;
    }
    elsif ($e = Exception::Class->caught()) {
      (ref $e && $e->can("rethrow")) ? $e->rethrow : die $e;
    }
  }
  return 1;
}

# remove_entry(entity), remove_entry(entity, key), remove_entry(entity, key, value)
sub remove_entry {
  my $self = shift;
  my ($entity, $key, $value) = @_;
  unless ($self->type eq $entity->entity_type) {
    REST::Neo4p::LocalException->throw(
      "Can't modify a ".$self->type." index by referring to a  ".$entity->entity_type."\n"
     );
  }
  my @addl_components;
  local $REST::Neo4p::HANDLE;
  REST::Neo4p->set_handle($self->_handle);
  my $agent = REST::Neo4p->agent;
  my $rq = 'delete_'.$self->_action;
  if (defined $key) {
    if (defined $value) {
      @addl_components = ($key, uri_escape($value,$unsafe), $$entity);
    }
    else { # !defined $value
      @addl_components = ($key, $$entity);
    }
  }
  else { # !defined $key && !defined $value
    @addl_components = ($$entity);
  }
  eval {
    $agent->$rq($self->name, @addl_components);
  };
  my $e;
  if ($e = Exception::Class->caught('REST::Neo4p::Exception')) {
    # TODO : handle different classes
    $e->rethrow;
  }
  elsif ($@) {
    ref $@ ? $@->rethrow : die $@;
  }
  return 1;
}

sub find_entries {
  my $self = shift;
  if ($self->is_batch) {
    REST::Neo4p::NotSuppException->throw("find_entries method not supported in batch mode (yet)\n");
  }
  my ($key, $value) = @_;
  my ($query) = @_;
  my $decoded_resp;
  local $REST::Neo4p::HANDLE;
  REST::Neo4p->set_handle($self->_handle);
  my $agent = REST::Neo4p->agent;
  my $rq = 'get_'.$self->_action;
  if ($value) { # exact key->value match
    eval {
      $decoded_resp = $agent->$rq( $self->name,
				   $key, uri_escape($value,$unsafe) );
    };
    my $e;
    if ($e = Exception::Class->caught('REST::Neo4p::Exception')) {
      # TODO : handle different classes
      $e->rethrow;
    }
    elsif ($@) {
      ref $@ ? $@->rethrow : die $@;
    }
  }
  else { # a lucene query string is first arg
    # note in below: cannot pass { query => $query } to 
    # request, neo4j interface doesn't work with "form fills"
    # must add the ?query string to the request url.
    eval {
      $decoded_resp = $agent->$rq( $self->name,
				   "?query=".uri_escape($query,$unsafe) );
    };
    if (my $e = Exception::Class->caught('REST::Neo4p::Exception')) {
      # TODO : handle different classes
      $e->rethrow;
    }
    elsif ($e = Exception::Class->caught) {
      (ref $e && $e->can("rethrow")) ? $e->rethrow : die $e;
    }
  }
  my @ret; 
  my $class = $self->type eq 'node' ? 'REST::Neo4p::Node' :
    'REST::Neo4p::Relationship';
  for (@$decoded_resp) {
    push @ret, $class->new_from_json_response($_);
  }
  return @ret;
}

# create_unique : route to correct method
sub create_unique {
  my $self = shift;
  my $method = 'create_unique_'.$self->type;
  $self->$method(@_);
}

# single key => value pair
sub create_unique_node {
  my $self = shift;
  my ($key, $value, $properties, $on_found) = @_;
  $on_found ||= 'get';
  $on_found = lc $on_found;
  unless ($self->type eq 'node') {
    REST::Neo4p::LocalException->throw("Can't create node on a non-node index\n");
  }
  unless (defined $key && defined $value && 
	    defined $properties && (ref $properties eq 'HASH')) {
    REST::Neo4p::LocalException->throw("Args required: key => value, hashref_of_properties\n");
  }
  unless ( $on_found =~ /^get|fail$/ ) {
    REST::Neo4p::LocalException->throw("on_found parameter (4th arg) must be one of 'get', 'fail'\n");
  }
  local $REST::Neo4p::HANDLE;
  REST::Neo4p->set_handle($self->_handle);
  my $agent = REST::Neo4p->agent;
  my $rq = "post_".$self->_action;
  my $restq = 'uniqueness='.($on_found eq 'get' ? 'get_or_create' : 'create_or_fail');
  my $decoded_resp;
  eval {
    $decoded_resp = $agent->$rq([join('?',$self->name,$restq)],
				{ key => $key,
				  value => $value,
				  properties => $properties}
			       );
  };
  if (my $e = Exception::Class->caught('REST::Neo4p::ConflictException')) {
    if ($on_found eq 'fail') {
      return; # user expects to get nothing back if not found
    }
    else {
      $e->rethrow; # uh oh, better bail
    }
  }
  elsif ($e = Exception::Class->caught) {
    (ref $e && $e->can("rethrow")) ? $e->rethrow : die $e;
  }
  return REST::Neo4p::Node->new_from_json_response($decoded_resp);
}

sub create_unique_relationship {
  my $self = shift;
  my ($key, $value, $from_node, $to_node, $rel_type, $properties, $on_found) = @_;
  $on_found ||= 'get';
  $on_found = lc $on_found;
  unless ($self->type eq 'relationship') {
    REST::Neo4p::LocalException->throw("Can't create relationship on a non-relationship index\n");
  }
  unless (defined $key && defined $value && 
	    defined $from_node && defined $to_node && 
	      defined $rel_type &&
		(ref $from_node eq 'REST::Neo4p::Node') &&
		  (ref $to_node eq 'REST::Neo4p::Node') ) {
    REST::Neo4p::LocalException->throw("Args required: key => value, from_node => to_node, rel_type\n");
  }
  unless (!defined $properties || (ref $properties eq 'HASH')) {
    REST::Neo4p::LocalException->throw("properties parameter (6th arg) must be undef or hashref of properties\n");
  }
  unless ( $on_found =~ /^get|fail$/ ) {
    REST::Neo4p::LocalException->throw("on_found parameter (7th arg) must be one of 'get', 'fail'\n");
  }
  local $REST::Neo4p::HANDLE;
  REST::Neo4p->set_handle($self->_handle);
  my $agent = REST::Neo4p->agent;
  my $rq = "post_".$self->_action;
  my $restq = 'uniqueness='.($on_found eq 'get' ? 'get_or_create' : 'create_or_fail');
  my $decoded_resp;
  my %json_params = ( key => $key,
		      value => $value,
		      start => $from_node->_self_url,
		      end => $to_node->_self_url,
		      type => $rel_type );
  $json_params{properties} = $properties if defined $properties;
  eval {
    $decoded_resp = $agent->$rq([join('?',$self->name,$restq)],
				\%json_params);
  };
  if (my $e = Exception::Class->caught('REST::Neo4p::ConflictException')) {
    if ($on_found eq 'fail') {
      return; # user expects to get nothing back if not found
    }
    else {
      $e->rethrow; # uh oh, better bail
    }
  }
  elsif ($e = Exception::Class->caught) {
    (ref $e && $e->can("rethrow")) ? $e->rethrow : die $e;
  }
  return REST::Neo4p::Relationship->new_from_json_response($decoded_resp);
}

# index name
sub name { ${$_[0]} }
# index type (node or relationship)
sub type { 
  my $self = shift;
  $self->_entry && $self->_entry->{type}
}
sub _action { 
  my $self = shift;
  $self->_entry && $self->_entry->{action}
}

# unused Entity methods
sub set_property { not_supported() }
sub get_property { not_supported() }
sub get_properties { not_supported() }
sub remove_property { not_supported() }

sub not_supported {
  REST::Neo4p::NotSuppException->throw( __PACKAGE__." does not support this method\n" );
}

=head1 NAME

REST::Neo4p::Index - Neo4j index object

=head1 SYNOPSIS

 $node_idx = REST::Neo4p::Index->new('node', 'my_node_index');
 $rel_idx = REST::Neo4p::Index->new('relationship', 'my_rel_index');
 $fulltext_idx = REST::Neo4p::Index->new('node', 'my_ft_index',
                                    { type => 'fulltext',
                                      provider => 'lucene' });
 $node_idx->add_entry( $ShaggyNode, 'pet' => 'ScoobyDoo' );
 $node_idx->add_entry( $ShaggyNode,
   'pet' => 'ScoobyDoo',
   'species' => 'Dog',
   'genotype' => 'ScSc',
   'episodes_featured' => 2343 );

 @returned_nodes = $node_idx->find_entries('pet' => 'ScoobyDoo');
 @returned_nodes = $node_idx->find_entries('pet:Scoob*');
 $node_idx->remove_entry( $JosieNode, 'hair' => 'red' );

=head1 DESCRIPTION

REST::Neo4p::Index objects represent Neo4j node and relationship indexes.

=head1 USAGE NOTE - VERSION 4.0

I<TL;DR - Using indexes in REST::Neo4p on Neo4j 4.0 should just work.>

Index objects were originally designed to encapsulate Neo4j "explicit"
indexes, which map nodes/relationships to a key-value pair.

As of Neo4j version 4.0, explicit indexes are not supported. Since
there may be applications using REST::Neo4p depending on the Index
functionality, the agent based on L<Neo4j::Driver> uses fulltext
indexes under the hood to emulate explicit indexes. This agent is used
automatically with Neo4j version 4.0 servers.

=head1 METHODS

=over

=item new()

 $node_idx = REST::Neo4p::Index->new('node', 'my_node_index');
 $rel_idx = REST::Neo4p::Index->new('relationship', 'my_rel_index');
 $fulltext_idx = REST::Neo4p::Index->new('node', 'my_ft_index',
                                    { type => 'fulltext',
                                      provider => 'lucene' });
 # Neo4j 4.0+
 $rel_idx = REST::Neo4p::Index->new('relationship', 'my_rel_index', {rtype => "my_reln_type"});


Creates a new index of the type given in the first argument, with the
name given in the second argument. The optional third argument is a
hashref containing an index configuration as provided for in the Neo4j
API.

I<Note>: For Neo4j 4.0+, REST::Neo4p emulates an explicit index using a
fulltext index. Fulltext indexes on relationships require specifying a
relationship type. To do this, include the key C<rtype> in the third
argument hashref.

=item remove()

 $index->remove()

B<CAUTION>: This method removes the index from the database and destroys the object.

=item name()

 $idx_name = $index->name()

=item type()

 if ($index->type eq 'node') { $index->add_entry( $node, $key => $value ); }

=item add_entry()

 $index->add_entry( $node, $key => $value );
 $index->add_entry( $node, $key1 => $value1, $key2 => $value2,...);
 $index->add_entry( $node, $key_value_hashref );

=item remove_entry()

 $index->remove_entry($node);
 $index->remove_entry($node, $key);
 $index->remove_entry($node, $key => $value);

=item find_entries()

 @returned_nodes = $node_index->find_entries($key => $value);
 @returned_rels = $rel_index->find_entries('pet:Scoob*');

In the first form, an exact match is sought. In the second (i.e., when
a single string argument is passed), the argument is interpreted as a
query string and passed to the index as such. The Neo4j default is
L<Lucene|http://lucene.apache.org/core/3_5_0/queryparsersyntax.html>.

C<find_entries()> is not supported in batch mode.

=item create_unique()

 $node = $index->create_unique( name => 'fred', 
                                { name => 'fred', state => 'unshaven'} );

 $reln = $index->create_unique( name => 'married_to',
                                $node => $wilma_node,
                                'MARRIED_TO');

Creates a unique node or relationship on the basis of presence or absence
of a matching item in the index. 

Optional final argument: one of 'get' or 'fail'. If 'get' (default), the 
matching item is returned if present. If 'fail', false is returned.

=back

=head1 SEE ALSO

L<REST::Neo4p>, L<REST::Neo4p::Relationship>, L<REST::Neo4p::Node>.

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
