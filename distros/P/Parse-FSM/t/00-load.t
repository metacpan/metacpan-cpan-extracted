#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'Parse::FSM' ) || print "Bail out!
";
}

diag( "Testing Parse::FSM $Parse::FSM::VERSION, Perl $], $^X" );
