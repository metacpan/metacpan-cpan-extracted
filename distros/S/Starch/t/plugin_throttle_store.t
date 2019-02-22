#!/usr/bin/env perl
use 5.008001;
use strictures 2;

use Test2::V0;
use Test::Starch;
use Starch;

Test::Starch->new(
    plugins => ['::ThrottleStore'],
)->test();

done_testing;
