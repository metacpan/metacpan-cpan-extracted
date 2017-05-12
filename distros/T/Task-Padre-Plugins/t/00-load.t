#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Task::Padre::Plugins' );
}

diag( "Testing Task::Padre::Plugins $Task::Padre::Plugins::VERSION, Perl $], $^X" );
