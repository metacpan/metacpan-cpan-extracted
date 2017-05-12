#!/usr/bin/perl
# $Id: 91-pod-coverage.t 4092 2009-02-24 17:46:48Z andrew $

use Test::More;
eval "use Test::Pod::Coverage";
plan skip_all => "Test::Pod::Coverage required for testing pod coverage" if $@;
all_pod_coverage_ok();




