#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Regexp::Common::microsyntax' ) || print "Bail out!
";
}

diag( "Testing Regexp::Common::microsyntax $Regexp::Common::microsyntax::VERSION, Perl $], $^X" );
