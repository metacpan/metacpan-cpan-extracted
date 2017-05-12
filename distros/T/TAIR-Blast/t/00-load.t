#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'TAIR::Blast' ) || print "Bail out!
";
}

diag( "Testing TAIR::Blast $TAIR::Blast::VERSION, Perl $], $^X" );
