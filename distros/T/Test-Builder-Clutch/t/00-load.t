#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::Builder::Clutch' ) || print "Bail out!
";
}

diag( "Testing Test::Builder::Clutch $Test::Builder::Clutch::VERSION, Perl $], $^X" );
