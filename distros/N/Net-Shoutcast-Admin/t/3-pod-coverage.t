#!/usr/bin/perl

# Test POD coverage
#
# $Id: 3-pod-coverage.t 223 2008-02-12 23:41:36Z davidp $


use strict;
use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" 
    if $@;
all_pod_coverage_ok();