#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Pod::Coverage;

my @modules = qw {
    Parallel::PreForkManager
};

plan tests => scalar @modules;

foreach my $module ( @modules ) {
    pod_coverage_ok( $module );
}

