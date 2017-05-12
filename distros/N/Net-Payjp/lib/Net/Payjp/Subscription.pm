package Net::Payjp::Subscription;

use strict;
use warnings;

use base 'Net::Payjp::Resource';

sub pause{
  my $self = shift;
  my $id = shift;
  $self->id($id) if $id;

  $self->_request(method => 'POST', url => $self->_instance_url.'/pause');
}

sub resume{
  my $self = shift;
  my $id = shift;
  $self->id($id) if $id;

  $self->_request(method => 'POST', url => $self->_instance_url.'/resume');
}

sub cancel{
  my $self = shift;
  my $id = shift;
  $self->id($id) if $id;

  $self->_request(method => 'POST', url => $self->_instance_url.'/cancel');
}

1;
