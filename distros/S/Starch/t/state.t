#!/usr/bin/env perl
use strictures 2;

use Test2::V0;
use Test::Starch;

Test::Starch->new->test_state();

done_testing;
