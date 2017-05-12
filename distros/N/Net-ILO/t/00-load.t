#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::ILO' );
}

diag( "Testing Net::ILO $Net::ILO::VERSION, Perl $], $^X" );
