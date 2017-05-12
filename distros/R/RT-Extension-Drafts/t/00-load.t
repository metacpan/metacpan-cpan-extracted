#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'RT::Extension::Drafts' );
}

diag( "Testing RT::Extension::Drafts $RT::Extension::Drafts::VERSION, Perl $], $^X" );
