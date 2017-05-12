#!perl

use Test::More tests => 1;

BEGIN {
	require_ok( 'MooseX::Contract' );
}

diag( "Testing MooseX::Contract $MooseX::Contract::VERSION, Perl $], $^X" );
