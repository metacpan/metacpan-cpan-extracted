#!perl -T

use Test::More tests => 1;

BEGIN {
        use_ok( 'Roku::RCP' );
}

diag( "Testing Roku::RCP $Roku::RCP::VERSION, Perl $], $^X" );
