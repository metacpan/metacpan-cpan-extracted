#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

test_items(
    "a candle, 13 zorkmids" => {
        appearance       => 'candle',
        quantity         => 1,
        cost_each        => 13,
        total_cost       => 13,
    },
    "9 candles, 26 zorkmids each" => {
        appearance       => 'candle',
        quantity         => 9,
        cost_each        => 26,
        total_cost       => 234,
    },
    "a tinning kit, no charge" => {
        appearance       => 'tinning kit',
        quantity         => 1,
        cost_each        => 0,
        total_cost       => 0,
    },
    "4 food rations, no charge" => {
        appearance       => 'food ration',
        quantity         => 4,
        cost_each        => 0,
        total_cost       => 0,
    },
    "a splint mail, price 106 zorkmids, finest quality" => {
        appearance       => 'splint mail',
        quantity         => 1,
        cost_each        => 106,
        total_cost       => 106,
    },
    "an uncursed scroll of destroy armor, price 150 zorkmids" => {
        identity   => 'scroll of destroy armor',
        quantity   => 1,
        cost_each  => 150,
        total_cost => 150,
        buc        => 'uncursed',
    },
    "an uncursed +0 cloak of magic resistance, no charge" => {
        identity    => 'cloak of magic resistance',
        quantity    => 1,
        cost_each   => 0,
        total_cost  => 0,
        buc         => 'uncursed',
        enchantment => '+0',
    },
    "a wand of cold (0:7), no charge" => {
        identity   => 'wand of cold',
        charges    => 7,
        recharges  => 0,
        buc        => 'uncursed',
        cost_each  => 0,
        total_cost => 0,
    },
    "a candelabrum (no candles attached), no charge" => {
        identity         => 'Candelabrum of Invocation',
        candles_attached => 0,
        cost_each        => 0,
        total_cost       => 0,
    },
);

done_testing;
