#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'RT::Extension::MandatoryFields' );
}

diag( "Testing RT::Extension::MandatoryFields $RT::Extension::MandatoryFields::VERSION, Perl $], $^X" );
