#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::LimeLight::Purge' );
}

diag( "Testing Net::LimeLight::Purge $Net::LimeLight::Purge::VERSION, Perl $], $^X" );
