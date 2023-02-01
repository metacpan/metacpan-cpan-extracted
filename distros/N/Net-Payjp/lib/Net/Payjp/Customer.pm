package Net::Payjp::Customer;

use strict;
use warnings;

use base 'Net::Payjp';

use Net::Payjp::Customer::Card;
use Net::Payjp::Customer::Subscription;

sub create{
  my $self = shift;
  my %p = @_;

  $self->_request(method => 'POST', url => $self->_class_url, param => \%p);
}

sub retrieve{
  my $self = shift;
  my $id = shift;
  $self->id($id) if $id;

  $self->_request(method => 'GET', url => $self->_instance_url);
}

sub save{
  my $self = shift;
  my %p = @_;

  $self->_request(method => 'POST', url => $self->_instance_url, param => \%p);
}

sub all{
  my $self = shift;
  my %p = @_;

  $self->_request(method => 'GET', url => $self->_class_url, param => \%p);
}

sub delete{
  my $self = shift;

  $self->_request(method => 'DELETE', url => $self->_instance_url);
}

sub cus_id{
  my $self = shift;
  $self->{cus_id} = shift if @_;
  return $self->{cus_id};
}

sub card{
  my $self = shift;
  $self->{cus_id} = shift;
  my $card = Net::Payjp::Customer::Card->new(api_key => $self->api_key);
  $card->cus_id($self->{cus_id});
  return $card;
}

sub subscription{
  my $self = shift;
  $self->{cus_id} = shift;
  my $sub = Net::Payjp::Customer::Subscription->new(api_key => $self->api_key);
  $sub->cus_id($self->{cus_id});
  return $sub;
}

1;
