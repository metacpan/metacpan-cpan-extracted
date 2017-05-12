#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Task::Twitter' );
}

diag( "Testing Task::Twitter $Task::Twitter::VERSION, Perl $], $^X" );
