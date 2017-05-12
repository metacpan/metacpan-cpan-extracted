#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::SMS::MyTMN' );
}

diag( "Testing Net::SMS::MyTMN $Net::SMS::MyTMN::VERSION, Perl $], $^X" );
