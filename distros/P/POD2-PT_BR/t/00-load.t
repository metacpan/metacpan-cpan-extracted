#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'POD2::PT_BR' );
}

diag( "Testing POD2::PT_BR $POD2::PT_BR::VERSION, Perl $], $^X" );
