#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::Most;

# Skip if doing a regular install
plan skip_all => "Author tests not required for installation"
    unless ( $ENV{AUTOMATED_TESTING} );

# Ensure a recent version of Test::Pod::Coverage
my $min_version = 1.08;
eval "use Test::Pod::Coverage $min_version";
plan skip_all => "Test::Pod::Coverage $min_version required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
$min_version = 0.18;
eval "use Pod::Coverage $min_version";
plan skip_all => "Pod::Coverage $min_version required for testing POD coverage"
    if $@;

all_pod_coverage_ok();
