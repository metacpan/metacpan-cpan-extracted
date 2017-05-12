#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MooseX::FSM' );
}

diag( "Testing MooseX::FSM $MooseX::FSM::VERSION, Perl $], $^X" );
