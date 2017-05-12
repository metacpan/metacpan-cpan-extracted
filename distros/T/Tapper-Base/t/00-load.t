#!perl -T

use Test::More tests => 1;

BEGIN {
        use_ok( 'Tapper::Base' );
}

diag( "Testing Tapper::Base $Tapper::Base::VERSION, Perl $], $^X" );
