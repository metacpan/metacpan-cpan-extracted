#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Task::Latemp' );
}

diag( "Testing Task::Latemp $Task::Latemp::VERSION, Perl $], $^X" );
