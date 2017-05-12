#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

my $pool = NetHack::ItemPool->new;
my $inv = $pool->inventory;

my $sword = $pool->new_item("m - a +1 long sword (weapon in hand)");
ok($sword->is_wielded, "our sword is wielded");

$inv->update($sword);
is($inv->weapon, $sword, "creating an item (weapon in hand) updated our wielded weapon");

my $excal = $pool->new_item("f - the +3 Excalibur (weapon in hand)");
ok($excal->is_wielded, "Excalibur is wielded");

is($inv->weapon, $sword, "we still use a regular long sword");

$inv->update($excal);

is($inv->weapon, $excal, "we switched to Excalibur after updating inventory");

ok(!$sword->is_wielded, "wielding Excalibur means our sword is no longer wielded");

$inv->remove('f');
ok(!$excal->is_wielded, "Excalibur is no longer wielded; it left our inventory");
ok(!$inv->has_weapon, "no weapon");

my $boots = $pool->new_item("a pair of combat boots");
ok(!$boots->is_worn, "not worn yet");
is($inv->boots, undef, "no boots yet");

$boots->is_worn(1);
ok($boots->is_worn, "worn now");
is($inv->boots, $boots, "wearing our boots");

$boots->is_worn(0);
ok(!$boots->is_worn, "not worn");
is($inv->boots, undef, "not wearing our boots");

my $opal = $pool->new_item("an opal ring");
ok(!$opal->is_worn, "not worn yet");
is($inv->left_ring, undef, "no ring yet");

$opal->hand("left");
is($opal->hand, "left", "worn on left hand now");
ok($opal->is_worn, "worn now");
is($inv->left_ring, $opal, "wearing our left-hand ring");

$opal->hand(undef);
is($opal->hand, undef, "no longer on a hand");
ok(!$opal->is_worn, "no longer worn");
is($inv->left_ring, undef, "no longer wearing our left-hand ring");

$opal->hand("right");
is($opal->hand, "right", "worn on right hand now");
ok($opal->is_worn, "worn now");
is($inv->right_ring, $opal, "wearing our right-hand ring");

my $wire = $pool->new_item("a wire ring (on right hand)");
is($wire->hand, "right", "worn on right hand");
ok($wire->is_worn, "worn");
is($inv->right_ring, $wire, "wearing our new right-hand ring");

is($opal->hand, undef, "opal no longer on a hand");
ok(!$opal->is_worn, "opal no longer worn");

done_testing;
