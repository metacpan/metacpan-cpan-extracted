#!perl -wT
# $Id: pod_coverage.t 996 2005-12-03 01:37:51Z claco $
use strict;
use warnings;
use Test::More;

eval 'use Test::Pod::Coverage 1.04';
plan skip_all => 'Test::Pod::Coverage 1.04' if $@;

eval 'use Pod::Coverage 0.14';
plan skip_all => 'Pod::Coverage 0.14 not installed' if $@;

my $trustme = {
    trustme =>
    [qr/^(check_.*|supportedMethods)$/]
};

all_pod_coverage_ok($trustme);
