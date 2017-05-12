#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Task::Dancer2' ) || print "Bail out!
";
}

diag( "Testing Task::Dancer2 $Task::Dancer2::VERSION, Perl $], $^X" );
