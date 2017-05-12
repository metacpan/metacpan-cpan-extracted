#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

test_items(
    "n - a dwarvish mithril-coat" => {
        ac => 6,
        mc => 3,
    },
    "n - a +1 dwarvish mithril-coat" => {
        ac => 7,
        mc => 3,
    },
    "m - a cornuthaum" => {
        ac => 0,
        mc => 2,
    },
    "l - a mummy wrapping" => {
        ac => 0,
        mc => 1,
    },
    "k - a food ration" => {
        nutrition_each => 800,
        time           => 5,
    },
    "j - a violet gem" => {
        hardness => 'soft',
        softness => 'soft',
    },
    "j - a green gem" => {
        hardness => undef,
        softness => undef,
    },
    "j - an emerald" => {
        hardness => 'hard',
        softness => 'hard',
    },
    "i - a wand of wishing" => {
        maxcharges => 3,
        zaptype    => 'nodir',
    },
    "h - a wand of death" => {
        maxcharges => 8,
        zaptype    => 'ray',
    },
    "g - a wand of striking" => {
        maxcharges => 8,
        zaptype    => 'beam',
    },
    "f - a ring of adornment" => {
        chargeable => 1,
    },
    "f - a ring of slow digestion" => {
        chargeable => 0,
    },
    "f - an opal ring" => {
        chargeable => undef,
    },
    "e - a scroll of genocide" => {
        ink => 30,
    },
    "e - a scroll of mail" => {
        ink => 2,
    },
    "e - an unlabeled scroll" => {
        ink => 0,
    },
    "d - a spellbook of finger of death" => {
        ink       => 70,
        level     => 7,
        time      => 80,
        emergency => 0,
        role      => undef,
    },
    "d - a spellbook of healing" => {
        ink       => 10,
        level     => 1,
        time      => 2,
        emergency => 1,
        role      => undef,
    },
    "d - a spellbook of magic mapping" => {
        ink       => 50,
        level     => 5,
        time      => 35,
        emergency => 0,
        role      => 'Arc',
    },
    "c - a spetum" => {
        sdam  => 'd6+1',
        ldam  => '2d6',
        tohit => 0,
        hands => 2,
    },
    "c - a long sword" => {
        sdam  => 'd8',
        ldam  => 'd12',
        tohit => 0,
        hands => 1,
    },
    "b - a bag of tricks" => {
        charge => 20,
    },
    "b - a bag of holding" => {
        charge => 0,
    },
    "a - a pick-axe" => {
        sdam  => 'd6',
        ldam  => 'd3',
        tohit => 0,
        hands => 1,
    },
    "z - a unicorn horn" => {
        sdam  => 'd12',
        ldam  => 'd12',
        tohit => '1',
        hands => 2,
    },
);

done_testing;
