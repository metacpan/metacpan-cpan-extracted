#!/usr/bin/env perl
use lib 't/lib';
use constant testing_method => 'quantity';
use Test::NetHack::Item;

test_items(
    "a - a +1 long sword (weapon in hand)" => 1,
    "A - an uncursed +0 orcish ring mail"  => 1,
    "k - the Eye of the Aethiopica"        => 1,
    "j - 2 slime molds"                    => 2,
    "m - 23 uncursed rocks"                => 23,
    '$ - 3 gold pieces'                    => 3,
    "3 gold pieces"                        => 3,
);

done_testing;
