#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'SMS::Send::Clickatell' );
}

diag( "Testing SMS::Send::Clickatell $SMS::Send::Clickatell::VERSION, Perl $], $^X" );
