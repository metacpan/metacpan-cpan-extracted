#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Template::Patch' );
}

diag( "Testing Template::Patch $Template::Patch::VERSION, Perl $], $^X" );
