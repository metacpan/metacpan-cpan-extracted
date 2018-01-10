#!perl

use Test::More tests => 1;

BEGIN {
  use_ok('PDL::Algorithm::Center');
}

diag( "Testing PDL::Algorithm::Center $PDL::Algorithm::Center::VERSION, Perl $], $^X" );
