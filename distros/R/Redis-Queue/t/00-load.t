#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Redis::Queue' ) || print "Bail out!
";
}

diag( "Testing Redis::Queue $Redis::Queue::VERSION, Perl $], $^X" );
