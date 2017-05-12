#!/usr/bin/env perl
use lib 't/lib';
use constant testing_method => 'weight';
use Test::NetHack::Item;

test_items(
    "oil lamp"               => 20,
    "magic lamp"             => 20,
    "lamp"                   => 20,
    "tooled horn"            => 18,
    "horn"                   => 18,
    "potion of water"        => 20,
    "2 potions of water"     => 40,
    "brown potion"           => 20,
    "2 brown potions"        => 40,
    "a wooden ring"          => 3,
    "a scroll labeled KIRJE" => 5,
    "an amulet of ESP"       => 20,
    "gray dragon scale mail" => 40,
    "a gray stone"           => undef,
    "a luckstone"            => 10,
    "a loadstone"            => 500,
    "a bag of holding"       => undef,
);

done_testing;
