#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
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

# Over lib/, not everything reachable in @INC. all_pod_coverage_ok() walks the
# built blib, which carries ExtUtils::Depends' generated Install/Files.pm - a
# file nobody writes, nobody reads, and which has no POD by construction - and
# it keeps reporting modules whose source has since been deleted.
my @modules = all_modules('lib');
plan tests => scalar @modules;
pod_coverage_ok($_) for @modules;
