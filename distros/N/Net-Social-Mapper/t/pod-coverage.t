#!perl

use strict;
use warnings;
use Test::More;
eval 'use Test::Pod::Coverage 1.04';
plan skip_all => 'Test::Pod::Coverage 1.04 required for testing POD coverage' if $@;
my @modules   = Test::Pod::Coverage::all_modules();
plan tests => scalar(@modules);
#pod_coverage_ok($_, { coverage_class => 'Pod::Coverage::CountParents' }) for @modules;
pod_coverage_ok($_) for @modules;

