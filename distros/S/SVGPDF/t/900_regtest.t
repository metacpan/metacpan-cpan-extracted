#! perl

use strict;
use warnings;

use Test::More;
our $api = "PDF::API2";

my $tests;
SKIP: {
      eval "require $api";
      if ( $@ ) {
	  diag "$api not installed";
	  skip "$api not installed, skipping tests", $tests = 1;
      }
      -d "t" && chdir "t";
      $tests = require "./900_regtest.pl";
}

done_testing($tests);
