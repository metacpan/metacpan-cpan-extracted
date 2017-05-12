#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'PagSeguro::Status' ) || print "Bail out!\n";
}

diag( "Testing PagSeguro::Status $PagSeguro::Status::VERSION, Perl $], $^X" );
