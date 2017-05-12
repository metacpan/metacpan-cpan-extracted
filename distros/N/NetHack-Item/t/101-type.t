#!/usr/bin/env perl
use lib 't/lib';
use constant testing_method => 'type';
use Test::NetHack::Item;

test_items(
    "x - 100 gold pieces"                             => "gold",
    "a - a +1 long sword (weapon in hand)"            => "weapon",
    "b - a blessed +0 dagger"                         => "weapon",
    "h - 8 +0 darts"                                  => "weapon",
    "s - a poisoned +0 arrow"                         => "weapon",
    "p - a +0 boomerang"                              => "weapon",
    "S - the +0 Cleaver"                              => "weapon",
    "c - an uncursed +3 small shield (being worn)"    => "armor",
    "o - an uncursed +0 banded mail"                  => "armor",
    "q - an uncursed +0 crystal plate mail"           => "armor",
    "h - the uncursed +0 Mitre of Holiness"           => "armor",
    "t - a set of gray dragon scales"                 => "armor",
    "x - an elven mithril-coat"                       => "armor",
    "d - 2 uncursed food rations"                     => "food",
    "m - a tin"                                       => "food",
    "j - a cursed tin of lichen"                      => "food",
    "K - an uncursed tin of newt meat"                => "food",
    "r - an uncursed partly eaten tripe ration"       => "food",
    "P - a blessed lichen corpse"                     => "food",
    "R - an uncursed guardian naga egg"               => "food",
    "w - an uncursed empty tin"                       => "food",
    "x - A slime mold"                                => "food",
    "N - an uncursed scroll of blank paper"           => "scroll",
    "k - an uncursed spellbook of blank paper"        => "spellbook",
    "T - the uncursed Book of the Dead"               => "spellbook",
    "C - an uncursed potion of water"                 => "potion",
    "k - the Eye of the Aethiopica"                   => "amulet",
    "U - the Amulet of Yendor"                        => "amulet",
    "e - a +0 pick-axe"                               => "tool",
    "f - a +0 grappling hook"                         => "tool",
    "t - an uncursed large box"                       => "tool",
    "m - the Master Key of Thievery"                  => "tool",
    "u - a figurine of a lichen"                      => "tool",
    "u - 53 rocks"                                    => "gem",
    "n - the Heart of Ahriman"                        => "gem",
    "v - a statue of a lichen"                        => "statue",
);

done_testing;
