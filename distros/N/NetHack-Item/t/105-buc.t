#!/usr/bin/env perl
use lib 't/lib';
use constant testing_method => 'buc';
use Test::NetHack::Item;

test_items(
    "a - a +1 long sword (weapon in hand)"  => 'uncursed',
    "i - a blessed murky potion"            => 'blessed',
    "j - a cursed skeleton key"             => 'cursed',
    "k - a scroll labeled THARR"            => undef,
    "l - a pick-axe"                        => undef,
    "l - a +0 pick-axe"                     => 'uncursed',
    "m - a long sword"                      => undef,
    "m - a blessed +4 long sword"           => 'blessed',
    "m - a +4 long sword"                   => 'uncursed',
    "m - wand of cold"                      => undef,
    "m - wand of cold (0:4)"                => 'uncursed',
    "m - bag of tricks"                     => undef,
    "m - bag of tricks (0:5)"               => 'uncursed',
    "n - a clear potion"                    => undef,
    "n - a potion of holy water"            => 'blessed',
    "o - a potion of unholy water"          => 'cursed',
    "n - 3 potions of holy water"           => 'blessed',
    "o - 3 potions of unholy water"         => 'cursed',
    "p - a unicorn horn"                    => undef,
    "p - a +2 unicorn horn"                 => 'uncursed',
);
done_testing;
