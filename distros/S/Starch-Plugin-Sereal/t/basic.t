#!/usr/bin/env perl
use strictures 2;

use Test2::V0;
use Test::Starch;

Test::Starch->new(
    plugins => ['::Sereal'],
)->test();

done_testing();
