#!perl -T

use Test::More tests => 1;

BEGIN {
   use_ok( 'Test::Command' );
}

diag( "Testing Test::Command $Test::Command::VERSION, Perl $], $^X" );
