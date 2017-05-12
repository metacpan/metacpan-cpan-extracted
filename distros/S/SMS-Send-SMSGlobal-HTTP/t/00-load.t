#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'SMS::Send::SMSGlobal::HTTP' ) || print "Bail out!
";
}

diag( "Testing SMS::Send::SMSGlobal::HTTP $SMS::Send::SMSGlobal::HTTP::VERSION, Perl $], $^X" );
