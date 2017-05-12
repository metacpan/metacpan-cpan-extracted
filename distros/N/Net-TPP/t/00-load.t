#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::TPP' ) || print "Bail out!
";
}

diag( "Testing Net::TPP $Net::TPP::VERSION, Perl $], $^X" );
