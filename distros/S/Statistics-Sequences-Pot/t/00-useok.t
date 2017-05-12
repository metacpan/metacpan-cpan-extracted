#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Statistics::Sequences::Pot', 0.12 ) || print "Bail out!\n";
}

diag( "Testing Statistics::Sequences::Pot $Statistics::Sequences::Pot::VERSION, Perl $], $^X" );
