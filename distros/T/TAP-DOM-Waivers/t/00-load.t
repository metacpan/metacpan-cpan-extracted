#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'TAP::DOM::Waivers' ) || print "Bail out!
";
}

diag( "Testing TAP::DOM::Waivers $TAP::DOM::Waivers::VERSION, Perl $], $^X" );
