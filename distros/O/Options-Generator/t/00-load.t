#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Options::Generator' ) || print "Bail out!\n";
}

diag( "Testing Options::Generator $Options::Generator::VERSION, Perl $], $^X" );
