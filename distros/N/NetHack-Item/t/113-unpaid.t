#!/usr/bin/env perl
use lib 't/lib';
use constant testing_method => 'total_cost';
use Test::NetHack::Item;

test_items(
    "a - a blessed +1 quarterstaff (weapon in hands) (unpaid, 15 zorkmids)" => 15,
    "p - a +0 studded leather armor (being worn) (unpaid, 15 zorkmids)" => 15,
    "x - 11 arrows (in quiver) (unpaid, 22 zorkmids)" => 242,
    "B - a tin (unpaid, 5 zorkmids)" => 5,
    "A - a tin (7 zorkmids)" => 7,
    "o - an uncursed triangular amulet (being worn) (unpaid, 150 zorkmids)" => 150,
    "d - an uncursed brass ring (on right hand) (unpaid, 100 zorkmids)" => 100,
    "c - a runed wand (unpaid, 200 zorkmids)" => 200,
    "I - a lamp (lit) (unpaid, 10 zorkmids)" => 10,
    "z - a yellow gem (unpaid, 1500 zorkmids)" => 1500,
    "H - a partly used candle" => 0,
);

done_testing;
