#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'SMS::Send::UK::Kapow' );
}

diag( "Testing SMS::Send::UK::Kapow $SMS::Send::UK::Kapow::VERSION, Perl $], $^X" );
