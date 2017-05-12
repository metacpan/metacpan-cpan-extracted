#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Report::Generator' ) || print "Bail out!
";
}

diag( "Testing Report::Generator $Report::Generator::VERSION, Perl $], $^X" );
