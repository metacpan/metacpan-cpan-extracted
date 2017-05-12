#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Notification::Center' );
}

diag( "Testing Notification::Center $Notification::Center::VERSION, Perl $], $^X" );
