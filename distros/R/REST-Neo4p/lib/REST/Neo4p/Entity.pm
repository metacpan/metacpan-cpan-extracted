#$Id$
use v5.10;
package REST::Neo4p::Entity;
use REST::Neo4p::Exceptions;
use Carp qw(croak carp);
use JSON;
use URI::Escape;
use strict;
use warnings;

# base class for nodes, relationships, indexes...
BEGIN {
  $REST::Neo4p::Entity::VERSION = '0.3020';
}

our $ENTITY_TABLE = {};

# new(\%properties)
# creates an entity in the db (with \%properties set), and returns
# a Perl object

sub new {
  my $class = shift;
  my ($entity_type) = $class =~ /.*::(.*)/;
  $entity_type = lc $entity_type;
  if ($entity_type eq 'entity') {
    REST::Neo4p::NotSuppException->throw("Cannot use ".__PACKAGE__." directly\n");
  }
  my ($properties) = (@_);
  my $url_components = delete $properties->{_addl_components};
  my $agent = REST::Neo4p->agent;
  REST::Neo4p::CommException->throw("Not connected\n") unless $agent;
  my $decoded_resp;
  eval {
    $decoded_resp = $agent->post_data(
      [$entity_type, $url_components ? @$url_components : ()],
      $properties
     );
  };
  if (my $e = REST::Neo4p::Exception->caught()) {
    # TODO : handle cases
    $e->rethrow;
  }
  elsif ($e = Exception::Class->caught()) {
    (ref $e && $e->can("rethrow")) ? $e->rethrow : die $e;
  }

  $decoded_resp->{self} ||= $agent->location if ref $decoded_resp;
  return ref($decoded_resp) ?
    $class->new_from_json_response($decoded_resp) :
      $class->new_from_batch_response($decoded_resp, @$url_components);
}

sub new_from_json_response {
  my $class = shift;
  my ($entity_type) = $class =~ /.*::(.*)/;
  $entity_type = lc $entity_type;
  if ($entity_type eq 'entity') {
    REST::Neo4p::NotSuppException->throw("Cannot use ".__PACKAGE__." directly\n");
  }
  my ($decoded_resp) = (@_);
  unless (defined $decoded_resp) {
    REST::Neo4p::LocalException->throw("new_from_json_response() called with undef argument\n");
  }
  unless ($ENTITY_TABLE->{$entity_type}{_actions}) {
    # capture the url suffix patterns for the entity actions:
    for (keys %$decoded_resp) {
      my ($suffix) = $decoded_resp->{$_} =~ m|.*$entity_type/[0-9]+/(.*)|;
      $ENTITY_TABLE->{$entity_type}{_actions}{$_} = $suffix;
    }
  }
  # "template" in next line is a kludge for get_indexes
  my $self_url  = $decoded_resp->{self} || $decoded_resp->{template};
  $self_url =~ s/{key}.*$//; # another kludge for get_indexes
  my ($obj) = $self_url =~ /([a-z0-9_]+)\/?$/i;
  my $tbl_entry = $ENTITY_TABLE->{$entity_type}{$obj};
  my ($start_id,$end_id);
  if ($decoded_resp->{start}) {
    ($start_id) = $decoded_resp->{start} =~ /([0-9]+)\/?$/;
    ($end_id) = $decoded_resp->{end} =~ /([0-9]+)\/?$/;
  }
  unless (defined $tbl_entry) {
    if ($decoded_resp->{template}) {     # another kludge for get_indexes
      ($decoded_resp->{type}) = $decoded_resp->{template} =~ m|index/([a-z]+)/|;
    }
    $tbl_entry = $ENTITY_TABLE->{$entity_type}{$obj} = {};
    $tbl_entry->{entity_type} = $entity_type;
    $tbl_entry->{self} = bless \$obj, $class;
    $tbl_entry->{self_url} = $self_url;
    $tbl_entry->{start_id} = $start_id;
    $tbl_entry->{end_id} = $end_id;
    $tbl_entry->{batch} = 0;
    $tbl_entry->{type} = $decoded_resp->{type};
    $tbl_entry->{_handle} = REST::Neo4p->handle; # current db handle
  }
  if ($REST::Neo4p::CREATE_AUTO_ACCESSORS && ($entity_type ne 'index')) {
    my $self =  $tbl_entry->{self};
    my $props = $self->get_properties;
    for (keys %$props) { $self->_create_accessors($_) unless $self->can($_); }
  }
  return $tbl_entry->{self};
}

sub new_from_batch_response {
  my $class = shift;
  my ($entity_type) = $class =~ /.*::(.*)/;
  $entity_type = lc $entity_type;
  if ($entity_type eq 'entity') {
    REST::Neo4p::NotSuppException->throw("Cannot use ".__PACKAGE__." directly\n");
  }
  my ($id_token) = (@_);
  my $tbl_entry = $ENTITY_TABLE->{$entity_type}{$id_token} = {};
  $tbl_entry->{entity_type} = $entity_type;
  $tbl_entry->{self} = bless \$id_token, $class;
  $tbl_entry->{self_url} = $id_token;
  $tbl_entry->{_handle} = REST::Neo4p->handle; # current handle
  $tbl_entry->{batch} = 1;
  $ENTITY_TABLE->{batch_objs}{$id_token} = $tbl_entry->{self};
  return $tbl_entry->{self};
}

# remove() - delete the node and destroy the object
sub remove {
  my $self = shift;
  return 1 unless defined $self->_handle; # gone already
  my @url_components = @_;
  my $entity_type = ref $self;
  $entity_type =~ s/.*::(.*)/\L$1\E/;
  local $REST::Neo4p::HANDLE;
  REST::Neo4p->set_handle($self->_handle);
  my $agent = REST::Neo4p->agent;
  eval {
    $agent->delete_data($entity_type, @url_components, $$self);
  };
  if (my $e = REST::Neo4p::NotFoundException->caught()) {
    1;
  }
  elsif ($e = Exception::Class->caught()) {
    (ref $e && $e->can("rethrow")) ? $e->rethrow : die $e;
  }
  $self->_deregister;
  return 1;
}
# set_property( { prop1 => $val1, prop2 => $val2, ... } )
# ret true if success, false if fail
sub set_property {
  my $self = shift;
  my ($props) = @_;
  REST::Neo4p::LocalException->throw("Arg must be a hashref\n") unless ref($props) && ref $props eq 'HASH';
  my $entity_type = ref $self;
  $entity_type =~ s/.*::(.*)/\L$1\E/;
  local $REST::Neo4p::HANDLE;
  REST::Neo4p->set_handle($self->_handle);
  my $agent = REST::Neo4p->agent;
  my $suffix = $self->_get_url_suffix('property');
  my @ret;
  $suffix =~ s|/[^/]*$||; # strip the '{key}' placeholder
  for (keys %$props) {
    eval {
      $agent->put_data([$entity_type,$$self,$suffix,
			$_], $props->{$_});
    };

    if (my $e = REST::Neo4p::NotFoundException->caught('REST::Neo4p::Exception')) {
      # TODO : handle different classes
      $e->rethrow;
    }
    elsif ($e = Exception::Class->caught()) {
      (ref $e && $e->can("rethrow")) ? $e->rethrow : die $e;
    }
  }
  # create accessors
  if ($REST::Neo4p::CREATE_AUTO_ACCESSORS) {
    for (keys %$props) { $self->_create_accessors($_) unless $self->can($_) }
  }
  return $self;
}

# @prop_values = get_property( qw(prop1 prop2 ...) )
sub get_property {
  my $self = shift;
  my @props = @_;
  my $entity_type = ref $self;
  $entity_type =~ s/.*::(.*)/\L$1\E/;
  local $REST::Neo4p::HANDLE;
  REST::Neo4p->set_handle($self->_handle);
  my $agent = REST::Neo4p->agent;
  REST::Neo4p::CommException->throw("Not connected\n") unless $agent;
  my $suffix = $self->_get_url_suffix('property');
  my @ret;
  $suffix =~ s|/[^/]*$||; # strip the '{key}' placeholder
  for (@props) {
    my $decoded_resp;
    eval {
      $decoded_resp = $agent->get_data($entity_type,$$self,$suffix,$_);
    };

    if ( my $e = REST::Neo4p::NotFoundException->caught()) {
      push @ret, undef;
    }
    elsif ( $e = Exception::Class->caught()) {
      (ref $e && $e->can("rethrow")) ? $e->rethrow : die $e;
    }
    else {
      _unescape($decoded_resp);
      push @ret, $decoded_resp;
    }
  }
  return @ret == 1 ? $ret[0] : @ret;
}

# $prop_hash = get_properties()
sub get_properties {
  my $self = shift;
  my $entity_type = ref $self;
  $entity_type =~ s/.*::(.*)/\L$1\E/;
  local $REST::Neo4p::HANDLE;
  REST::Neo4p->set_handle($self->_handle);
  my $agent = REST::Neo4p->agent;
  REST::Neo4p::CommException->throw("Not connected\n") unless $agent;
  my $suffix = $self->_get_url_suffix('property');
  $suffix =~ s|/[^/]*$||; # strip the '{key}' placeholder
  my $decoded_resp;
  eval {
    $decoded_resp = $agent->get_data($entity_type,$$self,$suffix);
  };
  my $e;
  if ($e = REST::Neo4p::NotFoundException->caught()) {
    return;
  }
  elsif ($e = Exception::Class->caught()) {
    (ref $e && $e->can("rethrow")) ? $e->rethrow : die $e;
  }
  _unescape($decoded_resp);
  return $decoded_resp;
}

sub _unescape {
  local $_ = shift;
  if (ref eq 'HASH') {
    while ( my ($k,$v) = each %$_ ) {
      if (ref $v eq '') {
	$_->{$k} = uri_unescape($v);
      }
      else {
	_unescape($v);
      }
    }
  }
  elsif (ref eq 'ARRAY') {
    foreach my $v (@$_) {
      _unescape($v);
    }
  }
}
# remove_property( qw(prop1 prop2 ...) )
sub remove_property {
  my $self = shift;
  my @props = @_;
  my $entity_type = ref $self;
  $entity_type =~ s/.*::(.*)/\L$1\E/;
  local $REST::Neo4p::HANDLE;
  REST::Neo4p->set_handle($self->_handle);
  my $agent = REST::Neo4p->agent;
  REST::Neo4p::CommException->throw("Not connected\n") unless $agent;
  my $suffix = $self->_get_url_suffix('property');
  $suffix =~ s|/[^/]*$||; # strip the '{key}' placeholder
  foreach (@props) {
    eval {
      $agent->delete_data($entity_type,$$self,$suffix,$_);
    };
    if (my $e = REST::Neo4p::Exception->caught()) {
      # TODO : handle different classes
      $e->rethrow;
    }
    elsif ($e = Exception::Class->caught()) {
      (ref $e && $e->can("rethrow")) ? $e->rethrow : die $e;
    }
  }
  return $self;
}

sub as_simple {
  my $self = shift;
  return;
}

sub simple_from_json_response {
  my $class = shift;
  my ($decoded_resp) = @_;
  return;
}

sub id { ${$_[0]} }
sub is_batch { shift->_entry->{batch} }
sub entity_type { shift->_entry->{entity_type} }

# $obj = REST::Neo4p::Entity->_entity_by_id($entity_type, $id[, $idx_type]) or
# $node_obj = REST::Neo4p::Node->_entity_by_id($id);
# $relationship_obj = REST::Neo4p::Relationship->_entity_by_id($id)
# $index_obj = REST::Neo4p::Index->_entity_by_id($id, $idx_type);
sub _entity_by_id {
  my $class = shift;
  REST::Neo4p::ClassOnlyException->throw() if (ref $class);
  
  my $entity_type = $class;
  my ($id, $idx_type);
  $entity_type =~ s/.*::(.*)/\L$1\E/;
  if ($entity_type eq 'entity') {
    ($entity_type,$id,$idx_type) = @_;
  }
  else {
    ($id,$idx_type) = @_;
  }
  if ($entity_type eq 'index' && !$idx_type) {
    REST::Neo4p::LocalException->throw("Index requested, but index type not provided in last arg\n");
  }
  my $new;
  unless ($ENTITY_TABLE->{$entity_type}{$id}) {
    # not recorded as object yet
    my $agent = REST::Neo4p->agent;
    REST::Neo4p::CommException->throw("Not connected\n") unless $agent;
    my ($rq, $decoded_resp);
    if ($entity_type eq 'index') {
      # get list of indexes and choose the one (if any) matching the 
      # given index name...
      $rq = "get_${idx_type}_index";
      eval {
	$decoded_resp = $agent->$rq();
      };
      my $e;
      if ($e = Exception::Class->caught('REST::Neo4p::Exception')) {
	# TODO : handle different classes
	$e->rethrow;
      }
      elsif ($@) {
	ref $@ ? $@->rethrow : die $@;
      }
      $decoded_resp = $decoded_resp->{$id};
      unless (defined $decoded_resp) {
	REST::Neo4p::NotFoundException->throw
	  (
	   message => "Index '$id' not found in db\n",
	   neo4j_message => "Neo4j call was successful, but index '$id'".
	                     "was not returned in the list of indexes\n"
	  );

      }
    }
    else {
      # usual way to get entities...
      $rq = "get_${entity_type}";

      eval {
	$decoded_resp = $agent->$rq($id);
      };

      if (my $e = REST::Neo4p::Exception->caught()) {
	# TODO : handle different classes
	$e->rethrow;
      }
      elsif ($e = Exception::Class->caught()) {
	(ref $e && $e->can("rethrow")) ? $e->rethrow : die $e;
      }
    }
    $new = ref($decoded_resp) ? $class->new_from_json_response($decoded_resp) :
      $class->new_from_batch_response($decoded_resp);
  }
  return $ENTITY_TABLE->{$entity_type}{$id}{self} || $new;
}

sub _get_url_suffix {
  my $self = shift;
  my ($action) = @_;
  my $entity_type = ref $self;
  $entity_type =~ s/.*::(.*)/\L$1\E/;
  return unless $ENTITY_TABLE->{$entity_type}{_actions};
  my $suffix = $ENTITY_TABLE->{$entity_type}{_actions}{$action};
}

# get the $ENTITY_TABLE entry for the object
sub _entry {
  my $self = shift;
  my $entity_type = ref $self;
  $entity_type =~ s/.*::(.*)/\L$1\E/;
  return $ENTITY_TABLE->{$entity_type}{$$self};
}
sub _self_url {
  my $self = shift;
  return $self->_entry->{self_url} if $self->_entry;
  return;
}

# get the $ENTITY_TABLE entry for the object
sub _handle { 
  my $self = shift;
  return $self->_entry->{_handle} if $self->_entry;
  return;
}

sub _deregister {
  my $self = shift;
  my $entity_type = ref $self;
  $entity_type =~ s/.*::(.*)/\L$1\E/;
  foreach (sort keys %{$ENTITY_TABLE->{$entity_type}{$$self}}) {
    delete $ENTITY_TABLE->{$entity_type}{$$self}{$_};
  }
  delete $ENTITY_TABLE->{$entity_type}{$$self};
}

sub DESTROY {
  my $self = shift;
  my $entity_type = ref $self;
  $entity_type =~ s/.*::(.*)/\L$1\E/;
  $self->_deregister if $ENTITY_TABLE->{$entity_type}{$$self}{entity_type};
}

sub _create_accessors {
  my $self = shift;
  my $class = ref $self;
  my ($prop_name) = @_;
  no strict qw(refs);
  *{$class."::$prop_name"} = sub {
    my $caller = shift;
    $caller->get_property( $prop_name );
  };
  *{$class."::set_$prop_name"} = sub { 
    shift->set_property( {$prop_name => $_[0]} );
  };
}

package REST::Neo4p::Simple;
use base 'REST::Neo4p::Entity';
use strict;
use warnings;
no warnings qw/once/;
BEGIN {
  $REST::Neo4p::Simple::VERSION = '0.3020';
}

sub new { $_[1] }

*new_from_json_response = \&new;
*simple_from_json_response = \&new;

1;

=head1 NAME

REST::Neo4p::Entity - Base class for Neo4j entities

=head1 SYNOPSIS

Not intended to be used directly. Use subclasses
L<REST::Neo4p::Node|REST::Neo4p::Node>,
L<REST::Neo4p::Relationship|REST::Neo4p::Relationship> and
L<REST::Neo4p::Node|REST::Neo4p::Index> instead.

=head1 DESCRIPTION

REST::Neo4p::Entity is the base class for the node, relationship and
index classes which should be used directly. The base class
encapsulates most of the L<REST::Neo4p::Agent> calls to the Neo4j
server, converts JSON responses to Perl references, acknowledges
errors, and maintains the main object table.

=head1 SEE ALSO

L<REST::Neo4p>, L<REST::Neo4p::Node>, L<REST::Neo4p::Relationship>,
L<REST::Neo4p::Index>.

=head1 AUTHOR

    Mark A. Jensen
    CPAN ID: MAJENSEN
    majensen -at- cpan -dot- org

=head1 LICENSE

Copyright (c) 2012-2017 Mark A. Jensen. This program is free software; you
can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

1;
