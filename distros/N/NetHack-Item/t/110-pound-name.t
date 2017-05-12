#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

test_items(
    "a - a +1 long sword (weapon in hand)",
     {generic_name => "", specific_name => ""},
    "f - a pair of fencing gloves named x",
     {generic_name => "", specific_name => "x"},
    "h - a sky blue potion named z y x",
     {generic_name => "", specific_name => "z y x"},
    "c - 16 uncursed flint stones named x (in quiver)",
     {generic_name => "", specific_name => "x"},
);
done_testing;
