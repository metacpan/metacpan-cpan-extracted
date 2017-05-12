#!perl -T

use strict;
use warnings;
use Test::More;
use Test::Deep;

use SilverGoldBull::API::Item;

plan tests => 4;

my $item = {
  'bid_price' => 468.37,
  'qty' => 1,
  'id' => '2706',
};

ok( my $item_obj = SilverGoldBull::API::Item->new($item), 'Create SilverGoldBull::API::Item object' );
can_ok($item_obj, qw(to_hashref));
ok( my $item_hash = $item_obj->to_hashref, 'Get item as a hashref' );
cmp_deeply($item, $item_hash, 'Items are the same');
