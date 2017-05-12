#!/usr/bin/env perl
use lib 't/lib';
use constant testing_method => 'type';
use Test::NetHack::Item;

test_items(
    "x - a samurai sword"                   => "weapon",
    "y - 5 crude daggers"                   => "weapon",
    "z - a broad pick"                      => "weapon",
    "f - a double-headed axe named Cleaver" => "weapon",
    "s - a poisoned arrow"                  => "weapon",
    "A - a crude ring mail"                 => "armor",
    "B - an apron"                          => "armor",
    "C - a faded pall"                      => "armor",
    "h - a visored helmet named The Mitre of Holiness" => "armor",
    "s - a pair of riding gloves"           => "armor",
    "i - an egg"                            => "food",
    "D - 2 tins"                            => "food",
    "f - a scroll labeled PRATYAVAYAH"      => "scroll",
    "m - a scroll labeled JUYED AWK YACC"   => "scroll",
    "E - 2 scrolls labeled FOOBIE BLETCH"   => "scroll",
    "l - an orange spellbook"               => "spellbook",
    "n - a light blue spellbook"            => "spellbook",
    "u - a magenta spellbook"               => "spellbook",
    "g - a papyrus spellbook"               => "spellbook",
    "N - a murky potion"                    => "potion",
    "O - a sky blue potion"                 => "potion",
    "P - 2 brown potions"                   => "potion",
    "h - a hexagonal amulet"                => "amulet",
    "G - a triangular amulet"               => "amulet",
    "H - a pyramidal amulet"                => "amulet",
    "q - a gold ring"                       => "ring",
    "t - a granite ring"                    => "ring",
    "v - an opal ring"                      => "ring",
    "K - a runed wand"                      => "wand",
    "L - a brass wand"                      => "wand",
    "M - an oak wand"                       => "wand",
    "g - 2 yellow gems"                     => "gem",
    "I - a green gem"                       => "gem",
    "Q - a gray stone"                      => "gem",
);

done_testing;
