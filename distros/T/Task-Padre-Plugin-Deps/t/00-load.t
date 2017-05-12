#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Task::Padre::Plugin::Deps' );
}

diag( "Testing Task::Padre::Plugin::Deps $Task::Padre::Plugin::Deps::VERSION, Perl $], $^X" );
