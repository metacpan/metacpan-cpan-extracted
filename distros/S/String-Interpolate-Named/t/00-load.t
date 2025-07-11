#! perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'String::Interpolate::Named' );
}

diag( "Testing String::Interpolate::Named $String::Interpolate::Named::VERSION, Perl $], $^X" );
