#!perl -T

use Test::More tests => 1;

sub register_hook { };
BEGIN {
	use_ok( 'Sledge::Plugin::DebugLeakChecker' );
}

diag( "Testing Sledge::Plugin::DebugLeakChecker $Sledge::Plugin::DebugLeakChecker::VERSION, Perl $], $^X" );
