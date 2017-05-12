#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Template::Stash::EscapeHTML' );
}

diag( "Testing Template::Stash::EscapeHTML $Template::Stash::EscapeHTML::VERSION, Perl $], $^X" );
