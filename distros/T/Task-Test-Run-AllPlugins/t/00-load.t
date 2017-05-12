#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Task::Test::Run::AllPlugins' );
}

diag( "Testing Task::Test::Run::AllPlugins $Task::Test::Run::AllPlugins::VERSION, Perl $], $^X" );
