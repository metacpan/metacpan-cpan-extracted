#!perl -T

use strict;
use warnings;
use Test::More;
use Test::Deep;

use SilverGoldBull::API::ShippingAddress;

plan tests => 4;

my $addr = {
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
ok( my $bill_addr = SilverGoldBull::API::ShippingAddress->new($addr), 'Create SilverGoldBull::API::ShippingAddress object' );
can_ok($bill_addr, qw(to_hashref));
ok( my $addr_from_object = $bill_addr->to_hashref, 'Get shipping address as a hashref' );
cmp_deeply($addr, $addr_from_object, 'Shipping addresses are the same');