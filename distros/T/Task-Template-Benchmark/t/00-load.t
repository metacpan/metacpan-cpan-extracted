#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Task::Template::Benchmark' ) || print "Bail out!
";
}

diag( "Testing Task::Template::Benchmark $Task::Template::Benchmark::VERSION, Perl $], $^X" );
