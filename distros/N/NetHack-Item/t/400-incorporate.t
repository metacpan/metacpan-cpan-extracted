#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

incorporate_ok "a +1 long sword" => "a blessed +1 long sword" => {
    buc => 'blessed',
};

incorporate_ok "a cursed +1 long sword" => "a long sword" => {
    buc         => 'cursed',
    enchantment => '+1',
};

incorporate_ok "a +1 long sword" => "the blessed greased +3 Excalibur (weapon in hand)" => {
    buc         => 'blessed',
    artifact    => 'Excalibur',
    enchantment => '+3',
    is_wielded  => 1,
    is_greased  => 1,
};

incorporate_ok "a blessed dagger" => "a poisoned dagger" => {
    buc         => 'blessed',
    is_poisoned => 1,
};

incorporate_ok "a black dragon corpse" => "a partly eaten black dragon corpse" => {
    is_partly_eaten => 1,
};

incorporate_ok "a potion of see invisible" => "a diluted potion of see invisible" => {
    is_diluted => 1,
};

incorporate_ok "a ring of see invisible" => "a ring of see invisible (on left hand)" => {
    hand => 'left',
};

incorporate_ok "a ring of see invisible (on left hand)" => "a ring of see invisible (on right hand)" => {
    hand => 'right',
};

incorporate_ok "a ring of see invisible (on right hand)" => "a ring of see invisible" => {
    hand => undef,
};

incorporate_ok "a heavy iron ball" => "a heavy iron ball (chained to you)" => {
    is_chained_to_you => 1,
};

incorporate_ok "a heavy iron ball (chained to you)" => "a heavy iron ball" => {
    is_chained_to_you => 0,
};

incorporate_ok "a wand of wishing (0:3)" => "a wand of wishing (0:2)" => {
    charges   => 2,
    recharges => 0,
};

incorporate_ok "a wand of wishing (0:0)" => "a wand of wishing (1:3)" => {
    charges   => 3,
    recharges => 1,
};

incorporate_ok "a wand of wishing (1:3)" => "a wand of wishing" => {
    charges   => 3,
    recharges => 1,
};

incorporate_ok "a long sword" => "a rusty long sword" => {
    rusty => 1,
};

incorporate_ok "a long sword" => "a very rusty long sword" => {
    rusty => 2,
};

incorporate_ok "a long sword" => "a thoroughly rusty long sword" => {
    rusty => 3,
};

incorporate_ok "a rusty long sword" => "a long sword" => {
    rusty => 0,
};

incorporate_ok "a long sword" => "a rustproof long sword" => {
    proofed => 1,
};

incorporate_ok "a rustproof long sword" => "a long sword" => {
    proofed => undef,
};

incorporate_ok "a magic lamp" => "a magic lamp (lit)" => {
    is_lit => 1,
};

incorporate_ok "a magic lamp (lit)" => "a magic lamp" => {
    is_lit => 0,
};

incorporate_ok "a candelabrum (no candles attached)" => "a candelabrum (1 candle attached)" => {
    candles_attached => 1,
};

incorporate_ok "a candelabrum (1 candle attached)" => "a candelabrum (7 candles attached)" => {
    candles_attached => 7,
};

incorporate_ok "a candelabrum (no candles attached)" => "a candelabrum (1 candle, lit)" => {
    candles_attached => 1,
    is_lit           => 1,
};

incorporate_ok "a candelabrum (7 candles attached)" => "a candelabrum (7 candles, lit)" => {
    candles_attached => 7,
    is_lit           => 1,
};

incorporate_ok "a candle" => "a partly used candle" => {
    is_partly_used => 1,
};

incorporate_ok "an uncursed +1 ring mail" => "an uncursed +1 ring mail (being worn)" => {
    is_worn => 1,
};

incorporate_ok "an uncursed +1 ring mail (being worn)" => "an uncursed +1 ring mail" => {
    is_worn => 0,
};

done_testing;
