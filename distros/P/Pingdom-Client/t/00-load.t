#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Pingdom::Client' ) || print "Bail out!
";
}

diag( "Testing Pingdom::Client $Pingdom::Client::VERSION, Perl $], $^X" );
