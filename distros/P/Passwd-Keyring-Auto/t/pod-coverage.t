#!perl

use strict;
use warnings;
use Test::More;

BEGIN {
    plan skip_all => 'these tests are for author testing'
      unless $ENV{AUTHOR_TESTING};
}

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

# I do not want coverage for internal modules, so ...
# all_pod_coverage_ok();
pod_coverage_ok("Passwd::Keyring::Auto");

done_testing;
