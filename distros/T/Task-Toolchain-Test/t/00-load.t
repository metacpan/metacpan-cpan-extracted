#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Task::Toolchain::Test' );
}

diag( "Testing Task::Toolchain::Test $Task::Toolchain::Test::VERSION, Perl $], $^X" );
