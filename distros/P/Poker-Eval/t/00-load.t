#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 24;

BEGIN {
    use_ok( 'Poker::Eval' ) || print "Bail out!\n";
    use_ok( 'Poker::Card' ) || print "Bail out!\n";
    use_ok( 'Poker::Deck' ) || print "Bail out!\n";
    use_ok( 'Poker::Dealer' ) || print "Bail out!\n";
    use_ok( 'Poker::Eval::Community' ) || print "Bail out!\n";
    use_ok( 'Poker::Eval::Omaha' ) || print "Bail out!\n";
    use_ok( 'Poker::Eval::Badugi' ) || print "Bail out!\n";
    use_ok( 'Poker::Eval::BlackMariah' ) || print "Bail out!\n";
    use_ok( 'Poker::Eval::Wild' ) || print "Bail out!\n";
    use_ok( 'Poker::Eval::Badugi27' ) || print "Bail out!\n";
    use_ok( 'Poker::Eval::HighSuit' ) || print "Bail out!\n";
    use_ok( 'Poker::Eval::Chinese' ) || print "Bail out!\n";
    use_ok( 'Poker::Score' ) || print "Bail out!\n";
    use_ok( 'Poker::Score::High' ) || print "Bail out!\n";
    use_ok( 'Poker::Score::Low8' ) || print "Bail out!\n";
    use_ok( 'Poker::Score::Low27' ) || print "Bail out!\n";
    use_ok( 'Poker::Score::LowA5' ) || print "Bail out!\n";
    use_ok( 'Poker::Score::Badugi' ) || print "Bail out!\n";
    use_ok( 'Poker::Score::Badugi27' ) || print "Bail out!\n";
    use_ok( 'Poker::Score::Chinese' ) || print "Bail out!\n";
    use_ok( 'Poker::Score::HighSuit' ) || print "Bail out!\n";
    use_ok( 'Poker::Score::Bring::High' ) || print "Bail out!\n";
    use_ok( 'Poker::Score::Bring::Low' ) || print "Bail out!\n";
    use_ok( 'Poker::Score::Bring::Wild' ) || print "Bail out!\n";
}

diag( "Testing Poker::Eval $Poker::Eval::VERSION, Perl $], $^X" );
