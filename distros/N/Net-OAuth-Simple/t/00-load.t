#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::OAuth::Simple' );
}

diag( "Testing Net::OAuth::Simple $Net::OAuth::Simple::VERSION, Perl $], $^X" );
