#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'RT::Extension::MandatoryRequestor' );
}

diag( "Testing RT::Extension::MandatoryRequestor $RT::Extension::MandatoryRequestor::VERSION, Perl $], $^X" );
