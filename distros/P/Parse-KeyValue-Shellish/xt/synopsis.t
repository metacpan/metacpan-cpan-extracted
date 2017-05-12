#!perl

use strict;
use warnings;
use Test::More;
eval {
    require Test::Synopsis::Expectation;
};
plan skip_all => "Test::Synopsis::Expectation is not installed." if $@;

Test::Synopsis::Expectation::all_synopsis_ok();

done_testing;

