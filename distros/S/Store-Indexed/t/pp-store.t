use strict;
use warnings;
use Test::More tests => 9;

BEGIN { use_ok('Store::Indexed::PP'); }

my $store = Store::Indexed::PP->new("color", "weight");
isa_ok($store, 'Store::Indexed::PP', "Object is created correctly");

$store->set_color(1, "red");
is($store->get_color(1), "red", "Store retrieves string value");

$store->set_weight(1, 50);
is($store->get_weight(1), 50, "Store retrieves integer value");

$store->set_color(1, "blue");
is($store->get_color(1), "blue", "Store overwrites existing value");

$store->set_color(2, "green");
is($store->get_color(1, ), "blue",  "ID 1 remains unchanged");
is($store->get_color(2, ), "green", "ID 2 retrieves correct value");

is($store->get_color(99,), undef, "Non-existent key returns undef");

undef $store;
pass("Object destroyed without segmentation fault");