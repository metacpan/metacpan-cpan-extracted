#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MooseX::Control' );
}

diag( "Testing MooseX::Control $MooseX::Control::VERSION, Perl $], $^X" );
