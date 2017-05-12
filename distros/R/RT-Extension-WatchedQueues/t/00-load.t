#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'RT::Extension::WatchedQueues' );
}

diag( "Testing RT::Extension::WatchedQueues $RT::Extension::WatchedQueues::VERSION, Perl $], $^X" );
