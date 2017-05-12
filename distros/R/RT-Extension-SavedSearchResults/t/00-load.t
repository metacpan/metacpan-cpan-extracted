#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'RT::Extension::SavedSearchResults' );
}

diag( "Testing RT::Extension::SavedSearchResults $RT::Extension::SavedSearchResults::VERSION, Perl $], $^X" );


