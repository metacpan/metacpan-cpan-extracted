#!/usr/bin/env perl

use Test::More;

BEGIN {
   plan( skip_all => 'AUTHOR_TESTING not defined' )
      unless $ENV{AUTHOR_TESTING};
}

use Test::Pod::Coverage tests => 1;
pod_coverage_ok( all_modules() );
