#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Task::Pluggable' );
}

diag( "Testing Task::Pluggable $Task::Pluggable::VERSION, Perl $], $^X" );
