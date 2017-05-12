#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::Amazon::Signature' );
}

diag( "Testing Net::Amazon::Signature $Net::Amazon::Signature::VERSION, Perl $], $^X" );
