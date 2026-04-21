#! perl

use strict;
use warnings;

use Test::More;
our $api = "PDF::Builder";

my $tests;
SKIP: {
      eval "require $api";
      if ( $@ ) {
	  diag "$api not installed";
	  skip "$api not installed, skipping tests", $tests = 1;
      }
      eval { $api->VERSION(3.027) };
      if ( $@ ) {
	  diag "$api must be 3.027 or newer";
	  skip "$api must be 3.027 or newer, skipping tests", $tests = 1;
      }
      -d "t" && chdir "t";
      $tests = require "./900_regtest.pl";
}

done_testing($tests);
