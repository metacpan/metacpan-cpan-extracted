package Net::Payjp::Customer::Card;

use strict;
use warnings;

use base 'Net::Payjp';

sub create{
  my $self = shift;
  my %p = @_;

  $self->_request(method => 'POST', url => $self->_instance_url, param => \%p);
}

sub retrieve{
  my $self = shift;
  my $id = shift;
  $self->id($id) if $id;

  $self->_request(method => 'GET', url => $self->_instance_url.'/'.$self->id);
}

sub save{
  my $self = shift;
  my %p = @_;

  $self->_request(method => 'POST', url => $self->_instance_url.'/'.$self->id, param => \%p);
}

sub delete{
  my $self = shift;

  $self->_request(method => 'DELETE', url => $self->_instance_url.'/'.$self->id);
}

sub all{
  my $self = shift;
  my %p = @_;

  $self->_request(method => 'GET', url => $self->_instance_url, param => \%p);
}

sub cus_id{
  my $self = shift;
  $self->{cus_id} = shift if @_;
  return $self->{cus_id};
}

sub _instance_url{
  my $self = shift;
  return $self->api_base.'/v1/customers/'.$self->cus_id.'/cards';
}

1;
