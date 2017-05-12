#!perl -T

use strict;
use warnings;
use Test::More;
use Test::Deep;

use SilverGoldBull::API;
use SilverGoldBull::API::Order;
use SilverGoldBull::API::Item;
use SilverGoldBull::API::ShippingAddress;
use SilverGoldBull::API::BillingAddress;

plan tests => 5;

my $bill_addr = undef;
my $ship_addr = $bill_addr = {
  'city' => 'Calgary',
  'first_name' => 'John',
  'region' => 'AB',
  'email' => 'sales@silvergoldbull.com',
  'last_name' => 'Smith',
  'postcode' => 'T2P 5C5',
  'street' => '888 - 3 ST SW, 10 FLOOR - WEST TOWER',
  'phone' => '+1 (403) 668 8648',
  'country' => 'ca'
};

my $shipping = SilverGoldBull::API::ShippingAddress->new($ship_addr);
my $billing = SilverGoldBull::API::BillingAddress->new($bill_addr);

my $item = {
  'bid_price' => 468.37,
  'qty' => 1,
  'id' => '2706',
};
my $item_obj = SilverGoldBull::API::Item->new($item);

my $order_hash = {
  "currency" => "USD",
  "declaration" => "TEST",
  "shipping" => $shipping,
  "billing"  => $billing,
  "shipping_method" => "1YR_STORAGE",
  items => [$item_obj],
  "payment_method" => "paypal",
};

ok( my $order = SilverGoldBull::API::Order->new($order_hash), 'Create SilverGoldBull::API::Order object' );
can_ok($order, qw(to_hashref));

my $order_hash_raw = {
  "currency" => "USD",
  "declaration" => "TEST",
  "shipping" => {
    'city' => 'Calgary',
    'first_name' => 'John',
    'region' => 'AB',
    'email' => 'sales@silvergoldbull.com',
    'last_name' => 'Smith',
    'postcode' => 'T2P 5C5',
    'street' => '888 - 3 ST SW, 10 FLOOR - WEST TOWER',
    'phone' => '+1 (403) 668 8648',
    'country' => 'ca'
  },
  "billing"  => {
    'city' => 'Calgary',
    'first_name' => 'John',
    'region' => 'AB',
    'email' => 'sales@silvergoldbull.com',
    'last_name' => 'Smith',
    'postcode' => 'T2P 5C5',
    'street' => '888 - 3 ST SW, 10 FLOOR - WEST TOWER',
    'phone' => '+1 (403) 668 8648',
    'country' => 'ca'
  },
  "shipping_method" => "1YR_STORAGE",
  items => [{
    'bid_price' => 468.37,
    'qty' => 1,
    'id' => '2706',
  }],
  "payment_method" => "paypal",
};

ok( my $order_raw = SilverGoldBull::API::Order->new($order_hash_raw), 'Create SilverGoldBull::API::Order object' );
can_ok($order_raw, qw(to_hashref));
cmp_deeply($order_hash_raw, $order_raw->to_hashref, 'Orders are the same');

