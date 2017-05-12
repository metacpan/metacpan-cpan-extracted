#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'String::FriendlyID' ) || print "Bail out!
";
}

diag( "Testing String::FriendlyID $String::FriendlyID::VERSION, Perl $], $^X" );
