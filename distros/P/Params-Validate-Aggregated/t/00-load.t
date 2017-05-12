#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok('Params::Validate::Aggregated');
}

diag( "Testing Params::Validate::Aggregated $Params::Validate::Aggregated::VERSION, Perl $], $^X" );
