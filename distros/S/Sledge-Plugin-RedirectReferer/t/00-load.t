#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Sledge::Plugin::RedirectReferer' );
}

diag( "Testing Sledge::Plugin::RedirectReferer $Sledge::Plugin::RedirectReferer::VERSION, Perl $], $^X" );
