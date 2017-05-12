#!/usr/bin/env perl
use lib 't/lib';

use Test::NetHack::Item;

test_items(
    "x - a samurai sword" => {
        appearance    => "samurai sword",
        identity      => "katana",
        possibilities => ["katana"],
    },
    "y - a crude dagger" => {
        appearance    => "crude dagger",
        identity      => "orcish dagger",
        possibilities => ["orcish dagger"],
    },
    "z - a broad pick" => {
        appearance    => "broad pick",
        identity      => "dwarvish mattock",
        possibilities => ["dwarvish mattock"],
    },
    "f - a double-headed axe named Cleaver" => {
        appearance    => "double-headed axe",
        identity      => "battle-axe",
        possibilities => ["battle-axe"],
    },
    "f - a battle-axe named Cleaver" => {
        appearance    => "double-headed axe",
        identity      => "battle-axe",
        possibilities => ["battle-axe"],
    },
    "f - a pyramidal amulet named The Eye of the Aethiopica" => {
        appearance    => "pyramidal amulet",
        artifact => undef, is_artifact => undef,
    },
    "f - an amulet of ESP named The Eye of the Aethiopica" => {
        appearance    => undef,
        identity      => "amulet of ESP", artifact => "Eye of the Aethiopica", is_artifact => 1
    },
    "X - a visored helmet named The Mitre of Holiness" => {
        appearance    => "visored helmet",
        identity      => undef, artifact => undef, is_artifact => undef,
    },
    "X - the helm of brilliance named The Mitre of Holiness" => {
        appearance    => undef,
        identity      => "helm of brilliance", artifact => 'Mitre of Holiness', is_artifact => 1
    },
    "A - a crude ring mail" => {
        appearance    => "crude ring mail",
        identity      => "orcish ring mail",
        possibilities => ["orcish ring mail"],
    },
    "B - an apron" => {
        appearance    => "apron",
        identity      => "alchemy smock",
        possibilities => ["alchemy smock"],
    },
    "C - a faded pall" => {
        appearance    => "faded pall",
        identity      => "elven cloak",
        possibilities => ["elven cloak"],
    },
    "s - a pair of riding gloves" => {
        appearance    => "riding gloves",
        identity      => undef,
        possibilities => ["gauntlets of dexterity", "gauntlets of fumbling", "gauntlets of power", "leather gloves"],
    },
    "i - an egg" => {
        appearance    => "egg",
        identity      => undef,
    },
    "b - 3 uncursed eggs" => {
        appearance    => "egg",
        identity      => undef,
    },
    "D - a tin" => {
        appearance    => "tin",
        identity      => undef,
    },
    "f - a scroll labeled PRATYAVAYAH" => {
        appearance    => "scroll labeled PRATYAVAYAH",
        identity      => undef,
    },
    "m - a scroll labeled JUYED AWK YACC" => {
        appearance    => "scroll labeled JUYED AWK YACC",
        identity      => undef,
    },
    "E - a scroll labeled FOOBIE BLETCH" => {
        appearance    => "scroll labeled FOOBIE BLETCH",
        identity      => undef,
    },
    "l - an orange spellbook" => {
        appearance    => "orange spellbook",
        identity      => undef,
    },
    "n - a light blue spellbook" => {
        appearance    => "light blue spellbook",
        identity      => undef,
    },
    "u - a magenta spellbook" => {
        appearance    => "magenta spellbook",
        identity      => undef,
    },
    "g - a papyrus spellbook" => {
        appearance    => "papyrus spellbook",
        identity      => "Book of the Dead",
        possibilities => ["Book of the Dead"],
    },
    "N - a murky potion" => {
        appearance    => "murky potion",
        identity      => undef,
    },
    "O - a sky blue potion" => {
        appearance    => "sky blue potion",
        identity      => undef,
    },
    "P - a brown potion" => {
        appearance    => "brown potion",
        identity      => undef,
    },
    "Q - a clear potion" => {
        appearance    => "clear potion",
        identity      => "potion of water",
        possibilities => ["potion of water"],
    },
    "h - a hexagonal amulet" => {
        appearance    => "hexagonal amulet",
        identity      => undef,
    },
    "G - a triangular amulet" => {
        appearance    => "triangular amulet",
        identity      => undef,
    },
    "H - a pyramidal amulet" => {
        appearance    => "pyramidal amulet",
        identity      => undef,
    },
    "q - a gold ring" => {
        appearance    => "gold ring",
        identity      => undef,
    },
    "t - a granite ring" => {
        appearance    => "granite ring",
        identity      => undef,
    },
    "v - an opal ring" => {
        appearance    => "opal ring",
        identity      => undef,
    },
    "K - a runed wand" => {
        appearance    => "runed wand",
        identity      => undef,
    },
    "L - a brass wand" => {
        appearance    => "brass wand",
        identity      => undef,
    },
    "M - an oak wand" => {
        appearance    => "oak wand",
        identity      => undef,
    },
    "7 candles" => {
        appearance    => "candle",
        identity      => undef,
        possibilities => ["tallow candle", "wax candle"],
    },
    "g - 2 yellow gems" => {
        appearance    => "yellow gem",
        identity      => undef,
    },
    "I - a green gem" => {
        appearance    => "green gem",
        identity      => undef,
    },
    "Q - a gray stone" => {
        appearance    => "gray stone",
        identity      => undef,
        possibilities => ["flint stone", "loadstone", "luckstone", "touchstone"],
    },
);

done_testing;
