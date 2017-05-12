#!/usr/bin/env perl
use lib 't/lib';
use Test::NetHack::Item;

incorporate_ok "a long sword" => "a blessed long sword" => {
    buc         => "blessed",
    is_blessed  => 1,
    is_holy     => 1,

    is_uncursed => 0,
    is_cursed   => 0,
    is_unholy   => 0,
};

incorporate_ok "a blessed long sword" => "a cursed long sword" => {
    buc         => "cursed",
    is_cursed   => 1,
    is_unholy   => 1,

    is_uncursed => 0,
    is_blessed  => 0,
    is_holy     => 0,
};

done_testing;
