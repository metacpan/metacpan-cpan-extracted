#!/usr/bin/env perl

use Test::Pod::Coverage tests => 1;
pod_coverage_ok( all_modules() );
