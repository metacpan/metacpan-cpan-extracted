package Rapi::Blog::DB::ResultSet::PreauthAction;

use strict;
use warnings;

use Moo;
extends 'DBIx::Class::ResultSet';

use RapidApp::Util ':all';
use Rapi::Blog::Util;
use Scalar::Util 'blessed';

use aliased 'Rapi::Blog::PreAuth::Actor::Error::NotFound';
use aliased 'Rapi::Blog::PreAuth::Actor::Error::Invalid';

use String::Random;
use Digest::SHA1;

sub unsealed {
  (shift)
    ->search_rs({ 'me.sealed' => 0 })
}

sub _hash_auth_key {
  my ($self, $key) = @_;
  die "missing required key argument" unless $key;
  Digest::SHA1->new->add($key)->hexdigest
}

sub create_auth_key {
  my ($self, $type, $user_id, $columns) = @_;
  
  my $key = String::Random->new->randregex('[a-z0-9A-Z]{15}');
  my $key_hash = $self->_hash_auth_key($key);
  
  my $create = {
    type       => $type,
    user_id    => $user_id,
    auth_key   => $key_hash
  };
  
  if($columns) {
    die "Optional 'columns' 3rd argument must be a hashref" 
      unless ((ref($columns)||'') eq 'HASH');
    
    my @ban_cols = ((keys %$create), 'user', 'type_id');
    exists $columns->{$_} and die "Custom/override of '$_' is not allowed" for (@ban_cols);
    %$create = (%$columns,%$create);
  }

  $self->create( $create ) and return $key
}


sub _matches_key {
  my ($self, $key) = @_;
  $self->search_rs({ 'me.auth_key' => $self->_hash_auth_key($key) })
}


sub lookup_key {
  my ($self, $key) = @_;
  $self->_matches_key($key)
    ->unsealed
    ->first
}

sub lookup_key_include_sealed {
  my ($self, $key) = @_;
  $self->_matches_key($key)
    ->first
}


sub _is_actor {
  my ($self, $obj) = @_;
  $obj && blessed($obj) && $obj->isa('Rapi::Blog::PreAuth::Actor')
}


# New: this is the common entrypoint for all client requests to 
# authenticate and execute a pre-auth action:
sub request_Actor {
  my $self = shift;
  my $c = shift || RapidApp->active_request_context or die "No active request";
  my $key = shift || $c->req->params->{key};
  
  my $Actor;
  
  try {
    $Actor = $self->_request_Actor($c,$key);
  }
  catch {
    my $err = shift;
    $self->_is_actor($err)
      # If an exception was thrown, but it is an Actor, return it:
      ? $Actor = $err
      # otherwise, rethrow:
      : die $err
  };
  
  die "Unknown error occured" unless $self->_is_actor($Actor);
  
  return $Actor
}


sub _request_Actor {
  my ($self, $c, $key) = @_;

  my $PreauthAction = $self->lookup_key($key) or NotFound->throw;
  
  my $Hit = $c
    ->model('DB::Hit')
    ->create_from_request({}, $c->request );
  
  # this is just for testing, not planning to stick with this content
  $PreauthAction->request_validate($Hit) or Invalid->throw(
    'This pre-authorization is no longer valid', 
    title => 'Permission denied', 
    subtitle => 'Pre-Authorization Invalid'
  );
  
  $PreauthAction->_new_actor_instance($c)
}



1;
