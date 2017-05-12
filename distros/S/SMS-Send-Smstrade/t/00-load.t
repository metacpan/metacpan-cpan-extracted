#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'SMS::Send::Smstrade' ) || print "Bail out!
";
}

diag( "Testing SMS::Send::Smstrade $SMS::Send::Smstrade::VERSION, Perl $], $^X" );
