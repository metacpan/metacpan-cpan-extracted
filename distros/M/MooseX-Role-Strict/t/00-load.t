#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MooseX::Role::Strict' );
}

diag( "Testing MooseX::Role::Strict $MooseX::Role::Strict::VERSION, Perl $], $^X" );
