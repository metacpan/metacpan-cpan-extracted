#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Parse::HP::ACU' ) || print "Bail out!
";
}

diag( "Testing Parse::HP::ACU $Parse::HP::ACU::VERSION, Perl $], $^X" );
