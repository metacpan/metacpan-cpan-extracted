#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Task::Smoke' );
}

diag( "Testing Task::Smoke $Task::Smoke::VERSION, Perl $], $^X" );
