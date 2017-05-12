#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::SMS::Massenversand' );
}

diag( "Testing Net::SMS::Massenversand $Net::SMS::Massenversand::VERSION, Perl $], $^X" );
