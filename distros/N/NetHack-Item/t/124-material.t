#!/usr/bin/env perl
use lib 't/lib';
use constant testing_method => 'material';
use Test::NetHack::Item;

test_items(
    "a - a boulder"                    => "mineral",
    "b - a potion of acid"             => "glass",
    "c - a smoky potion"               => "glass",
    "d - 23 gold pieces"               => "gold",
    "e - a tin of spinach"             => "metal",
    "f - 42 eggs"                      => "flesh",
    "g - a banana"                     => "veggy",
    "h - Croesus' corpse"              => "flesh",
    "i - a loadstone"                  => "mineral",
    "k - a worthless piece of red glass" => "glass",
    "l - a ruby"                       => "gemstone",
    "m - the +2 Cleaver"               => "iron",
    "n - a quarterstaff"               => "wood",
    "o - a large box"                  => "wood",
    "p - a mirror"                     => "glass",
    "q - an iron chain"                => "iron",
    "s - a ring of teleport control"   => undef,
    "u - a red spellbook"              => "paper",
    "v - a spellbook of knock"         => "paper",
    "D - a cheap plastic imitation of the Amulet of Yendor" => "plastic",
    "E - an amulet of strangulation"   => "iron",
    "F - an oval amulet"               => "iron",
    "G - a wand of fire"               => undef,
    "I - a scroll labeled DUAM XNAHT"  => "paper",
    "J - a scroll of amnesia"          => "paper",
    "w - a crystal plate mail" =>
        { material => "glass", is_metallic => 0 },
    "x - a helm of opposite alignment" =>
        { material => "iron", is_metallic => 1 },
    "y - a visored helmet" =>
        { material => "iron", is_metallic => 1 },
    "z - a pair of kicking boots" =>
        { material => "iron", is_metallic => 1 },
    "A - a pair of snow boots" =>
        { material => undef, is_metallic => undef },
    "B - a pair of levitation boots" =>
        { material => "leather", is_metallic => 0 },
    "K - a dwarvish mithril-coat" =>
        { material => "mithril", is_metallic => 1 },
);

TODO: {
    local $TODO = "We don't currently have a system for appearance-specific spoilers";
    test_items(
        "C - the Amulet of Yendor"         => undef,
        "j - a stone"                      => "mineral",
        "t - a moonstone ring"             => "mineral",
        "r - a wooden ring"                => "wood",
        "H - a maple wand"                 => "wood",
    );
}
done_testing;
