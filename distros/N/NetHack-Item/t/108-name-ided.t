#!/usr/bin/env perl
use lib 't/lib';
use NetHack::Monster::Spoiler;

use Test::NetHack::Item;

test_items(
    "x - 100 gold pieces" => {
        appearance    => "gold piece",
        identity      => "gold piece",
        possibilities => ["gold piece"],
    },
    "a - a +1 long sword (weapon in hand)" => {
        appearance    => "long sword",
        identity      => "long sword",
        possibilities => ["long sword"],
    },
    "b - a blessed +0 dagger" => {
        appearance    => "dagger",
        identity      => "dagger",
        possibilities => ["dagger"],
    },
    "h - 8 +0 darts" => {
        appearance    => "dart",
        identity      => "dart",
        possibilities => ["dart"],
    },
    "s - a poisoned +0 arrow" => {
        appearance    => "arrow",
        identity      => "arrow",
        possibilities => ["arrow"],
    },
    "p - a +0 boomerang" => {
        appearance    => "boomerang",
        identity      => "boomerang",
        possibilities => ["boomerang"],
    },
    "S - the +0 Cleaver" => {
        appearance    => "double-headed axe",
        identity      => "battle-axe",
        possibilities => ["battle-axe"],
        artifact      => 'Cleaver',
    },
    "X - the Eye of the Aethiopica" => {
        appearance    => undef,
        identity      => "amulet of ESP",
        possibilities => ["amulet of ESP"],
        artifact      => 'Eye of the Aethiopica',
    },
    "X - the Mitre of Holiness" => {
        appearance    => undef,
        identity      => "helm of brilliance",
        possibilities => ["helm of brilliance"],
        artifact      => 'Mitre of Holiness',
    },
    "c - an uncursed +3 small shield (being worn)" => {
        appearance    => "small shield",
        identity      => "small shield",
        possibilities => ["small shield"],
    },
    "o - an uncursed +0 banded mail" => {
        appearance    => "banded mail",
        identity      => "banded mail",
        possibilities => ["banded mail"],
    },
    "q - an uncursed +0 crystal plate mail" => {
        appearance    => "crystal plate mail",
        identity      => "crystal plate mail",
        possibilities => ["crystal plate mail"],
    },
    "t - a set of gray dragon scales" => {
        appearance    => "gray dragon scales",
        identity      => "gray dragon scales",
        possibilities => ["gray dragon scales"],
    },
    "d - 2 uncursed food rations" => {
        appearance    => "food ration",
        identity      => "food ration",
        possibilities => ["food ration"],
    },
    "j - a cursed tin of lichen" => {
        appearance    => "tin",
        identity      => "tin of lichen",
        possibilities => ["tin of lichen"],
    },
    "K - an uncursed tin of newt meat" => {
        appearance    => "tin",
        identity      => "tin of newt meat",
        possibilities => ["tin of newt meat"],
    },
    "r - an uncursed partly eaten tripe ration" => {
        appearance    => "tripe ration",
        identity      => "tripe ration",
        possibilities => ["tripe ration"],
    },
    "P - a blessed lichen corpse" => {
        appearance    => "lichen corpse",
        identity      => "lichen corpse",
        possibilities => ["lichen corpse"],
    },
    "R - an uncursed guardian naga egg" => {
        appearance    => "egg",
        identity      => "guardian naga egg",
        possibilities => ["guardian naga egg"],
    },
    "w - an uncursed empty tin" => {
        appearance    => "tin",
        identity      => "empty tin",
        possibilities => ["empty tin"],
    },
    "T - the uncursed Book of the Dead" => {
        appearance    => "papyrus spellbook",
        identity      => "Book of the Dead",
        possibilities => ["Book of the Dead"],
    },
    "C - an uncursed potion of water" => {
        appearance    => "clear potion",
        identity      => "potion of water",
        possibilities => ["potion of water"],
    },
    "U - the Amulet of Yendor" => {
        appearance    => "Amulet of Yendor",
        identity      => "Amulet of Yendor",
        possibilities => ["Amulet of Yendor"],
    },
    "e - a +0 pick-axe" => {
        appearance    => "pick-axe",
        identity      => "pick-axe",
        possibilities => ["pick-axe"],
    },
    "f - a +0 grappling hook" => {
        appearance    => "iron hook",
        identity      => "grappling hook",
        possibilities => ["grappling hook"],
    },
    "t - an uncursed large box" => {
        appearance    => "large box",
        identity      => "large box",
        possibilities => ["large box"],
    },
    "W - a blessed magic lamp (lit)" => {
        appearance    => "lamp",
        identity      => "magic lamp",
        possibilities => ["magic lamp"],
    },
    "m - the Master Key of Thievery" => {
        appearance    => "key",
        identity      => "skeleton key",
        possibilities => ["skeleton key"],
        artifact      => 'Master Key of Thievery',
    },
    "G - a cursed partly used wax candle (lit)" => {
        appearance    => "candle",
        identity      => "wax candle",
        possibilities => ["wax candle"],
    },
    "u - a figurine of a lichen" => {
        appearance    => "figurine of a lichen",
        identity      => "figurine of a lichen",
        possibilities => ["figurine of a lichen"],
        monster       => NetHack::Monster::Spoiler->lookup('lichen'),
    },
    "u - a figurine of an orc mummy" => {
        appearance    => "figurine of an orc mummy",
        identity      => "figurine of an orc mummy",
        possibilities => ["figurine of an orc mummy"],
        monster       => NetHack::Monster::Spoiler->lookup('orc mummy'),
    },
    "u - 53 rocks" => {
        appearance    => "rock",
        identity      => "rock",
        possibilities => ["rock"],
    },
    "n - the Heart of Ahriman" => {
        appearance    => "gray stone",
        identity      => "luckstone",
        possibilities => ["luckstone"],
        artifact      => 'Heart of Ahriman',
    },
    "v - a statue of a lichen" => {
        appearance    => "statue of a lichen",
        identity      => "statue of a lichen",
        possibilities => ["statue of a lichen"],
        monster       => NetHack::Monster::Spoiler->lookup('lichen'),
    },
    "v - a statue of an orc mummy" => {
        appearance    => "statue of an orc mummy",
        identity      => "statue of an orc mummy",
        possibilities => ["statue of an orc mummy"],
        monster       => NetHack::Monster::Spoiler->lookup('orc mummy'),
    },
);
done_testing;
