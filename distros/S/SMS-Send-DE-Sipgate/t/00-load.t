#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'SMS::Send::DE::Sipgate' ) || print "Bail out!
";
}

diag( "Testing SMS::Send::DE::Sipgate $SMS::Send::DE::Sipgate::VERSION, Perl $], $^X" );
