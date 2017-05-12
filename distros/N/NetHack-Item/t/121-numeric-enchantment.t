#!/usr/bin/env perl
use lib 't/lib';
use constant testing_method => 'numeric_enchantment';
use Test::NetHack::Item;

test_items(
    "a - a +1 long sword (weapon in hand)"           => 1,
    "f - the +0 Cleaver"                             => 0,
    "m - a blessed +4 long sword"                    => 4,
    "E - a blessed poisoned rusty corroded -1 arrow" => -1,
    "h - the uncursed +10 Mitre of Holiness"         => 10,
    "p - a -10 unicorn horn"                         => -10,
    "x - a robe"                                     => undef,
);
done_testing;
