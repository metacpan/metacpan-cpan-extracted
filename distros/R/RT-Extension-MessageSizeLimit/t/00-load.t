#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'RT::Extension::MessageSizeLimit' );
}

diag( "Testing RT::Extension::MessageSizeLimit $RT::Extension::MessageSizeLimit::VERSION, Perl $], $^X" );
