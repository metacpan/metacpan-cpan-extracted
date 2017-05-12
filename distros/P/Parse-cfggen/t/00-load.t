#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Parse::cfggen' ) || print "Bail out!
";
}

diag( "Testing Parse::cfggen $Parse::cfggen::VERSION, Perl $], $^X" );
