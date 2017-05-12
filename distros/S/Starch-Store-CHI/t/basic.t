#!/usr/bin/env perl
use strictures 2;

use Test::More;
use Test::Starch;

Test::Starch->new(
    store => {
        class  => '::CHI',
        chi => {
            driver => 'Memory',
            global => 0,
        },
    },
)->test();

done_testing();
