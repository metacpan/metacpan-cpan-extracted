#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'RT::Extension::MandatorySubject' );
}

diag( "Testing RT::Extension::MandatorySubject $RT::Extension::MandatorySubject::VERSION, Perl $], $^X" );
