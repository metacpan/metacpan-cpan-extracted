package Net::Payjp::Customer;

use strict;
use warnings;

use base 'Net::Payjp::Resource';

use Net::Payjp::Customer::Card;
use Net::Payjp::Customer::Subscription;

sub card{
  my $self = shift;
  my $cus_id = shift;
  $self->cus_id($cus_id);
  my $class = Net::Payjp::Customer::Card->new(
    api_key => $self->api_key,
    cus_id => $self->cus_id
  );
}

sub subscription{
  my $self = shift;
  my $cus_id = shift;
  $self->cus_id($cus_id);
  my $class = Net::Payjp::Customer::Subscription->new(
    api_key => $self->api_key,
    cus_id => $self->cus_id
  );
}

1;
