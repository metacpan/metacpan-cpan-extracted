#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::DBus::Skype' );
}

diag( "Testing Net::DBus::Skype $Net::DBus::Skype::VERSION, Perl $], $^X" );
