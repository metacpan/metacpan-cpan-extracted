#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MySQL::SlowLog::Filter' );
}

diag( "Testing MySQL::SlowLog::Filter $MySQL::SlowLog::Filter::VERSION, Perl $], $^X" );
