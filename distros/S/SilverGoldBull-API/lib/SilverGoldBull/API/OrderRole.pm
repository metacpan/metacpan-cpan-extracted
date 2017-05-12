package SilverGoldBull::API::OrderRole;

use strict;
use warnings;

use Mouse::Role;
use Mouse::Util::TypeConstraints;
use Scalar::Util qw(blessed);

use SilverGoldBull::API::ShippingAddress;
use SilverGoldBull::API::BillingAddress;
use SilverGoldBull::API::Item;

enum 'Declaration' => qw(TEST PROMISE_TO_PAY);

has 'currency'        => ( is => 'rw', isa => 'Str', required => 1 );
has 'declaration'     => ( is => 'rw', isa => 'Declaration', required => 1 );
has 'payment_method'  => ( is => 'rw', isa => 'Str', required => 1 );
has 'shipping_method' => ( is => 'rw', isa => 'Str', required => 1 );
has 'items'           => ( is => 'rw', isa => 'ArrayRef[HashRef]|ArrayRef[SilverGoldBull::API::Item]', required => 1 );
has 'shipping'        => ( is => 'rw', isa => 'HashRef|Maybe[SilverGoldBull::API::ShippingAddress]', required => 1 );
has 'billing'         => ( is => 'rw', isa => 'HashRef|Maybe[SilverGoldBull::API::BillingAddress]', required => 1 );

sub BUILD {
  my ($self) = @_;
  
  if ($self->shipping && (ref($self->shipping) eq 'HASH')) {
    my $shipping_obj = SilverGoldBull::API::ShippingAddress->new($self->shipping());
    $self->shipping($shipping_obj);
  }
  
  if ($self->billing && (ref($self->billing) eq 'HASH')) {
    my $billing_obj = SilverGoldBull::API::BillingAddress->new($self->billing());
    $self->billing($billing_obj);
  }
  
  if ($self->items && (ref($self->items) eq 'ARRAY')) {
    my $items = [];
    for my $item(@{$self->items}) {
      my $item_obj = $item;
      if (ref($item) eq 'HASH') {
        $item_obj = SilverGoldBull::API::Item->new($item);
      }
      
      push @{$items}, $item_obj;
    }
    
    $self->items($items);
  }
}

sub to_hashref {
  my ($self) = @_;
  my $hashref = {};
  for my $field (qw(currency declaration payment_method shipping_method shipping billing)) {
    if ($self->{$field}) {
      if (blessed($self->{$field}) && $self->{$field}->can('to_hashref')) {
        $hashref->{$field} = $self->{$field}->to_hashref();
      }
      else {
        $hashref->{$field} = $self->{$field};
      }
    }
  }

  $hashref->{items} = [ map { $_->to_hashref() }@{$self->items} ];

  return $hashref;
}

1;