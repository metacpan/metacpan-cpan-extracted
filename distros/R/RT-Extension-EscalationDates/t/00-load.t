#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'RT::Extension::EscalationDates' );
}

diag( "Testing RT::Extension::EscalationDates $RT::Extension::EscalationDates::VERSION, Perl $], $^X" );
