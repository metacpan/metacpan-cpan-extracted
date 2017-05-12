#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MooseX::CurriedHandles' );
}

diag( "Testing MooseX::CurriedHandles $MooseX::CurriedHandles::VERSION, Perl $], $^X" );
