#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MooseX::MultiInitArg' );
}

diag( "Testing MooseX::MultiInitArg $MooseX::MultiInitArg::VERSION, Perl $], $^X" );
