#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Proc::ProcessTable' ) || print "Bail out!\n";
}

diag( "Testing Proc::ProcessTable $Proc::ProcessTable::VERSION, Perl $], $^X" );
