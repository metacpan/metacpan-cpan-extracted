#!/usr/bin/env perl
use 5.008001;
use strictures 2;

use Test2::V0;
use Test::Starch;

Test::Starch->new->test_state();

done_testing;
