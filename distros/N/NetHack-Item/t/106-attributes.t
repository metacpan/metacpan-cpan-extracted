#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

test_items(
    "a - a +1 club" => {
        is_poisoned => 0,
        proofed     => undef,
        burnt       => 0,
        rusty       => 0,
        corroded    => 0,
        rotted      => 0,
    },
    "m - a blessed +4 long sword" => {
        is_poisoned => 0,
        proofed     => undef,
        burnt       => 0,
        rusty       => 0,
        corroded    => 0,
        rotted      => 0,
    },
    "s - a poisoned +0 arrow" => {
        is_poisoned => 1,
        proofed     => undef,
        burnt       => 0,
        rusty       => 0,
        corroded    => 0,
        rotted      => 0,
    },
    "C - a poisoned rusty +0 arrow" => {
        is_poisoned => 1,
        proofed     => undef,
        burnt       => 0,
        rusty       => 1,
        corroded    => 0,
        rotted      => 0,
    },
    "D - a poisoned very rusty corroded +0 arrow" => {
        is_poisoned => 1,
        proofed     => undef,
        burnt       => 0,
        rusty       => 2,
        corroded    => 1,
        rotted      => 0,
    },
    "E - a blessed poisoned rusty thoroughly corroded +1 arrow" => {
        is_poisoned => 1,
        proofed     => undef,
        burnt       => 0,
        rusty       => 1,
        corroded    => 3,
        rotted      => 0,
    },
    "F - a blessed greased poisoned rusty corroded +2 arrow" => {
        is_poisoned => 1,
        proofed     => undef,
        burnt       => 0,
        rusty       => 1,
        corroded    => 1,
        rotted      => 0,
    },
    "e - an uncursed rotted fireproof +0 leather armor (being worn)" => {
        proofed  => 1,
        burnt    => 0,
        rusty    => 0,
        corroded => 0,
        rotted   => 1,
    },
    "t - an uncursed greased partly used tallow candle (lit)" => {
        proofed        => undef,
        burnt          => 0,
        rusty          => 0,
        corroded       => 0,
        rotted         => 0,
        is_partly_used => 1,
    },
    "v - an uncursed burnt rotted partly used candle" => {
        burnt          => 1,
        rusty          => 0,
        corroded       => 0,
        rotted         => 1,
        is_partly_used => 1,
    },
    "f - an uncursed diluted smoky potion" => {
        is_greased => 0,
        is_diluted => 1,
    },
    "h - an uncursed partly eaten food ration" => {
        is_greased      => 0,
        is_partly_eaten => 1,
    },
);
done_testing;
