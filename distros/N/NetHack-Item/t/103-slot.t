#!/usr/bin/env perl
use lib 't/lib';
use constant testing_method => 'slot';
use Test::NetHack::Item;

test_items(
    "a - a +1 long sword (weapon in hand)" => 'a',
    "B + a blessed +0 alchemy smock"       => 'B',

    # if your inventory is full and you pick up an unusual item, # is the
    # overflow slot. you can have multiple items in # even!
    "# - 5 gold pieces"                    => '#',
    "# - a cursed gray stone"              => '#',
);

done_testing;
