#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'RT::Extension::SearchResults::XLS' );
}

diag( "Testing RT::Extension::SearchResults::XLS $RT::Extension::SearchResults::XLS::VERSION, Perl $], $^X" );
