#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

my $pool = NetHack::ItemPool->new;
my $inv = $pool->inventory;

my $shield = $pool->new_item("c - an uncursed +1 small shield (being worn)");
$inv->update($shield);
is($shield->numeric_enchantment, 1);
ok($shield->is_worn, 'is worn');

$inv->update($pool->new_item("c - an uncursed +3 small shield (being worn)"));
is($shield->numeric_enchantment, 3);
ok($shield->is_worn, 'is still worn');

is($inv->shield, $inv->get('c'), "Incorporating worn items leaves equipment consistent");

$inv->update($pool->new_item("c - an uncursed +5 small shield"));
is($shield->numeric_enchantment, 5);
ok(!$shield->is_worn, 'is no longer worn');
is($inv->shield, undef, "no longer wearing a shield");

done_testing;
