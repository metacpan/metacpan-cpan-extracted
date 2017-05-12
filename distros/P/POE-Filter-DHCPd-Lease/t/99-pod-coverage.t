#!/usr/bin/env perl
use lib qw(lib);
use Test::More;
eval 'use Test::Pod::Coverage; 1' or plan skip_all => 'Test::Pod::Coverage required';
all_pod_coverage_ok();
