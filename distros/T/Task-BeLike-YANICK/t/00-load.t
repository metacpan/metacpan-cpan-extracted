#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Task::BeLike::YANICK' );
}

diag( "Testing Task::BeLike::YANICK $Task::BeLike::YANICK::VERSION, Perl $], $^X" );
