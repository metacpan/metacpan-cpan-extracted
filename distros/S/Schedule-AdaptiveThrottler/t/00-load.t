#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Schedule::AdaptiveThrottler' ) || print "Bail out!
";
}

diag( "Testing Schedule::AdaptiveThrottler $Schedule::AdaptiveThrottler::VERSION, Perl $], $^X" );
