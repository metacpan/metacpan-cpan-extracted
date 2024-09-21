#!/usr/bin/env perl

use Test::More;

BEGIN {
   plan( skip_all => 'AUTHOR_TESTING not defined' )
      unless $ENV{AUTHOR_TESTING};
}

use Test::Pod 1.00;

all_pod_files_ok( all_pod_files( lib ) );
