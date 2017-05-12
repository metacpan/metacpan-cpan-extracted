#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::SMS::Optimus' );
}

diag( "Testing Net::SMS::Optimus $Net::SMS::Optimus::VERSION, Perl $], $^X" );
