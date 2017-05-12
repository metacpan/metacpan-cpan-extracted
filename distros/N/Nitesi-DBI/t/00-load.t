#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Nitesi::DBI' ) || print "Bail out!\n";
}

diag( "Testing Nitesi::DBI $Nitesi::DBI::VERSION, Perl $], $^X" );
