#!perl

use Test::More tests => 1;

BEGIN {
  use_ok('PDLx::DetachedObject');
}

diag( "Testing PDLx::DetachedObject $PDLx::DetachedObject::VERSION, Perl $], $^X" );
