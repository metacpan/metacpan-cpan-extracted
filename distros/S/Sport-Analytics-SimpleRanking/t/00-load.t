#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Sport::Analytics::SimpleRanking' ) || print "Bail out!
";
}

diag( "Testing Sport::Analytics::SimpleRanking $Sport::Analytics::SimpleRanking::VERSION, Perl $], $^X" );
