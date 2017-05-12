#!perl

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use strict;
use warnings;
use 5.010;

use Test::More;

eval 'use Test::MinimumVersion;';
plan skip_all => 'Test::MinimumVersion required for this test' if $@;
all_minimum_version_ok('5.010');
