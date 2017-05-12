#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'Poker::Robot' ) || print "Bail out!\n";
    use_ok( 'Poker::Robot::Login' ) || print "Bail out!\n";
    use_ok( 'Poker::Robot::Ring' ) || print "Bail out!\n";
    use_ok( 'Poker::Robot::Chair' ) || print "Bail out!\n";
}

diag( "Testing Poker::Robot $Poker::Robot::VERSION, Perl $], $^X" );
