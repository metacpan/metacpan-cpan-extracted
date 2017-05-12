#!perl -T

use strict;
use warnings;
use Test::More;
use Test::Deep;

use SilverGoldBull::API;
use SilverGoldBull::API::Quote;
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

my $quote_hash_with_obj = {
  "currency" => "USD",
  "declaration" => "TEST",
  "shipping" => $shipping,
  "billing"  => $billing,
  "shipping_method" => "1YR_STORAGE",
  items => [$item_obj],
  "payment_method" => "paypal",
};

ok( my $quote_with_obj = SilverGoldBull::API::Quote->new($quote_hash_with_obj), 'Create SilverGoldBull::API::Quote object' );
can_ok($quote_with_obj, qw(to_hashref));

my $quote_hash = {
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

ok( my $quote = SilverGoldBull::API::Quote->new($quote_hash), 'Create SilverGoldBull::API::Quote object' );
can_ok($quote, qw(to_hashref));
cmp_deeply($quote_hash, $quote->to_hashref, 'Quotas are the same');
