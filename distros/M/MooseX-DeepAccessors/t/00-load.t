#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MooseX::DeepAccessors' );
}

diag( "Testing MooseX::DeepAccessors $MooseX::DeepAccessors::VERSION, Perl $], $^X" );
