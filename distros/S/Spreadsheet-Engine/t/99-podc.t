#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

eval 'use Test::Pod::Coverage 1.00';

plan skip_all => 'Test::Pod::Coverage required for testing POD' if $@;
all_pod_coverage_ok({ coverage_class => 'Pod::Coverage::CountParents' });
