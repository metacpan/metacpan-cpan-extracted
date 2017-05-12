#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

my $pool = NetHack::ItemPool->new;

my $orange = $pool->new_item("3 blessed orange potions");
my $water = $pool->new_item("a potion of water");

my $orange_tracker = $orange->tracker;
my $water_tracker = $water->tracker;

$orange_tracker->rule_out("potion of sickness");

ok($orange->tracker, "got a tracker");
ok($orange->tracker->includes_possibility("potion of enlightenment"), "includes enlightenment");
ok(!$orange->tracker->includes_possibility("potion of sickness"), "doesn't include sickness");
ok(!$orange->tracker->includes_possibility("potion of water"), "doesn't include water");
ok(!$orange->is_diluted, "is_diluted");
is($orange->appearance, "orange potion", "appearance");
is($orange->identity, undef, "identity");
is($orange->quantity, 3, "quantity");
is($orange->buc, "blessed", "buc");

$orange->did_dilute_partially;
is($orange->tracker, $orange_tracker, "same tracker");
ok($orange->tracker->includes_possibility("potion of enlightenment"), "includes enlightenment");
ok(!$orange->tracker->includes_possibility("potion of sickness"), "doesn't include sickness");
ok(!$orange->tracker->includes_possibility("potion of water"), "doesn't include water");
ok($orange->is_diluted, "is_diluted");
is($orange->appearance, "orange potion", "appearance");
is($orange->identity, undef, "identity");
is($orange->quantity, 3, "quantity");
is($orange->buc, "blessed", "buc");

$orange->did_dilute_into_water;
is($orange->tracker, $water_tracker, "is now the water tracker");
ok(!$orange->is_diluted, "is_diluted");
is($orange->appearance, "clear potion", "appearance");
is($orange->identity, "potion of water", "identity");
is($orange->quantity, 3, "quantity");
is($orange->buc, "uncursed", "buc");

my $new_orange = $pool->new_item("an orange potion");
is($new_orange->tracker, $orange_tracker, "tracker");
ok($new_orange->tracker->includes_possibility("potion of enlightenment"), "includes enlightenment");
ok(!$new_orange->tracker->includes_possibility("potion of sickness"), "doesn't include sickness");
ok(!$new_orange->tracker->includes_possibility("potion of water"), "doesn't include water");

done_testing;
