#!perl

use strict;
use warnings;

use Test::More;
eval { use Test::Synopsis::Expectation };
plan skip_all => "Test::Synopsis::Expectation is not installed." if $@;

all_synopsis_ok();

done_testing;

