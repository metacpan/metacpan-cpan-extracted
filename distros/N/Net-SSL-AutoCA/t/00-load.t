#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::SSL::AutoCA' );
}

diag( "Testing Net::SSL::AutoCA $Net::SSL::AutoCA::VERSION, Perl $], $^X" );
