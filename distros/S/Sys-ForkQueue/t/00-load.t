#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'Sys::ForkQueue' ) || print "Bail out!
";
    use_ok( 'Sys::ForkAsync' ) || print "Bail out!
";
}

diag( "Testing Sys::ForkQueue $Sys::ForkQueue::VERSION, Perl $], $^X" );
