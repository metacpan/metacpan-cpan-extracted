#!perl

use Test::More tests => 1;

BEGIN {
  use_ok('PDL::FuncND');
}

diag( "Testing PDL::FuncND $PDL::FuncND::VERSION, Perl $], $^X" );
