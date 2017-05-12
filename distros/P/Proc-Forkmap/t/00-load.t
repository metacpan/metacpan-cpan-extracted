#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Proc::Forkmap' ) || print "Bail out!\n";
}

diag( "Testing Proc::Forkmap $Proc::Forkmap::VERSION, Perl $], $^X" );
