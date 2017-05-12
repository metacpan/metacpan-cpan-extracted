#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'RT::Extension::SearchResults::ODS' );
}

diag( "Testing RT::Extension::SearchResults::ODS $RT::Extension::SearchResults::ODS::VERSION, Perl $], $^X" );
