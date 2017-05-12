#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Script::isAperlScript' );
}

diag( "Testing Script::isAperlScript $Script::isAperlScript::VERSION, Perl $], $^X" );
