#!perl
use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage"
    unless eval "use Test::Pod::Coverage 1.08; 1";

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
plan skip_all => "Pod::Coverage 0.18 required for testing POD coverage"
    unless eval "use Pod::Coverage 0.18; 1";

all_pod_coverage_ok();
