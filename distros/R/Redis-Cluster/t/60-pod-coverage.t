#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

unless ($ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}) {
  plan(skip_all => 'AUTHOR_TESTING or RELEASE_TESTING is not set; skipping');
}

{
  ## no critic
  eval q(
    use Test::Pod::Coverage 1.08;
    use Pod::Coverage 0.18;
 );
};

plan(skip_all => 'Test::Pod::Coverage (>=1.08) '.
  'and Pod::Coverage (>=0.18) are required') if $@;

all_pod_coverage_ok('lib');
