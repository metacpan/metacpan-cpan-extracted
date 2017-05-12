#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Task::Dancer' ) || print "Bail out!
";
}

diag( "Testing Task::Dancer $Task::Dancer::VERSION, Perl $], $^X" );
