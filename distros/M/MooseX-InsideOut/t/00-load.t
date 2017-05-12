#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MooseX::InsideOut' );
}

diag( "Testing MooseX::InsideOut $MooseX::InsideOut::VERSION, Perl $], $^X" );
