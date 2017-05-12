#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

use NetHack::Item;
my $item = NetHack::Item->new("f - a wand of wishing named SWEET (0:3)" );

is($item->slot, 'f', "slot");
is($item->type, 'wand', "type");
is($item->specific_name, 'SWEET', "specific_name");
is($item->charges, 3, "charges");

$item->spend_charge;
$item->wield;
$item->buc("blessed");

is($item->charges, 2, "charges");
is($item->is_wielded, 1, "is_wielded");
is($item->is_blessed, 1, "is_blessed");
is($item->is_cursed, 0, "is_cursed");

done_testing;
