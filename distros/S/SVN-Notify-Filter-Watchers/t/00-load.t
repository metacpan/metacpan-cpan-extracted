#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'SVN::Notify::Filter::Watchers' );
}

diag( "Testing SVN::Notify::Filter::Watchers $SVN::Notify::Filter::Watchers::VERSION, Perl $], $^X" );
