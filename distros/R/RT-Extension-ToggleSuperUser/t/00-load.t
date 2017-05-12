#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'RT::Extension::ToggleSuperUser' );
}

diag( "Testing RT::Extension::ToggleSuperUser $RT::Extension::ToggleSuperUser::VERSION, Perl $], $^X" );
