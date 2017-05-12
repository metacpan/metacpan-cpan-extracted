#!perl
use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    unless eval "use Test::Pod::Coverage $min_tpc; 1";

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    unless eval "use Pod::Coverage $min_pc; 1";

all_pod_coverage_ok();
