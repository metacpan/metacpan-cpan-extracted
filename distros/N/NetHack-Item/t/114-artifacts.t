#!/usr/bin/env perl
use lib 't/lib';
use constant testing_method => 'is_artifact';
use Test::NetHack::Item;

test_items(
    (map { $_ => 1 }
        "Cleaver",
        "battle-axe named Cleaver",
        "double-headed axe named Cleaver",

        "the Master Key of Thievery",
        "key named The Master Key of Thievery",

        "silver bell",
        "candelabrum",
        "papyrus spellbook",
        "the Bell of Opening",
        "the Candelabrum of Invocation",
        "the Book of the Dead",

        "The Heart of Ahriman",
        "The Orb of Fate",
        "The Mitre of Holiness",

        "an amulet of ESP named The Eye of the Aethiopica",
        "a helm of brilliance named The Mitre of Holiness",
        "a luckstone named The Heart of Ahriman",

        "a quarterstaff named The Staff of Aesculapius",
        "a crystal ball named The Orb of Fate",

        "orcish dagger named Grimtooth",
        "crude dagger named Grimtooth",

        "elven dagger named Sting",

        "The Sceptre of Might",
        "a mace named The Sceptre of Might",
    ),

    (map { $_ => 0 }
        "battle-axe",
        "battle-axe named cleaver",
        "battle-axe named the Cleaver",
        "battle-axe named The Cleaver",
        "battle-axe called Cleaver",
        "double-headed axe called Cleaver",
        "angled poleaxe named Cleaver",
        "halberd named Cleaver",
        "angled poleaxe called Cleaver",
        "halberd called Cleaver",

        "skeleton key",
        "key named Master Key of Thievery",
        "key named the Master Key of Thievery",
        "key named foo Master Key of Thievery",
        "key named Master Key of the Thievery",
        "key called Master Key of Thievery",
        "key called the Master Key of Thievery",

        "r - a dull spellbook named The Book of the Dead",

        "an amulet versus poison named The Eye of the Aethiopica",
        "a helm of opposite alignment named Mitre of Holiness",
        "a loadstone named heart of ahriman",

        "a mace named the Scepter of Might",

        "a quarterstaff named The Orb of Fate",

        "a quarterstaff named The The Staff of Aesculapius",

        # not the exact names! case or lack of "The"
        "a visored helmet named the mitre of holiness",
        "a visored helmet named Mitre of Holiness",
        "a gray stone named the heart of ahriman",
        "a gray stone named Heart of Ahriman",
        "a pyramidal amulet named the eye of the aethiopica",
        "a pyramidal amulet named the Eye of the Aethiopica",
        "a pyramidal amulet named Eye of the Aethiopica",

        # naming an elven dagger "THE STING" names it "Sting"
        "elven dagger named THE STING",
        "elven broadsword named orcrist",
    ),

    (map { $_ => undef }
        "a gray stone named The Heart of Ahriman",
        "a pyramidal amulet named The Eye of the Aethiopica",
        "a visored helmet named The Mitre of Holiness",
    ),
);

done_testing;
