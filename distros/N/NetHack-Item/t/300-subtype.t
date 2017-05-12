#!/usr/bin/env perl
use lib 't/lib';
use NetHack::Monster::Spoiler;
use Test::NetHack::Item;

test_items(
    "a long sword" => {
        subtype => undef,
    },
    "a leather cloak" => {
        type          => 'armor',
        subtype       => 'cloak',
        possibilities => ['leather cloak'],
    },
    "the Mitre of Holiness" => {
        type          => 'armor',
        subtype       => 'helmet',
        possibilities => ['helm of brilliance'],
    },
    "bag of holding" => {
        type          => 'tool',
        subtype       => 'container',
        possibilities => ['bag of holding'],
    },
    "bag of tricks" => {
        type          => 'tool',
        subtype       => undef,
        possibilities => ['bag of tricks'],
    },
    "a lichen corpse" => {
        type    => 'food',
        subtype => 'corpse',
        monster => NetHack::Monster::Spoiler->lookup('lichen'),
    },
    "a food ration" => {
        type    => 'food',
        subtype => undef,
    },
);

done_testing;
