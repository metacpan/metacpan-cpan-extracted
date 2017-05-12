#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
#plan tests => 1;

eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;
plan skip_all => 'set TEST_POD to enable this test (developer only!)'
  unless $ENV{TEST_POD};
all_pod_coverage_ok();
