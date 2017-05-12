#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'TRD::DebugLog' );
}

diag( "Testing TRD::DebugLog $TRD::DebugLog::VERSION, Perl $], $^X" );
