#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::Twitpic' ) || print "Bail out!
";
}

diag( "Testing Net::Twitpic $Net::Twitpic::VERSION, Perl $], $^X" );
