#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'RPC::Any::Interface::PSGI' ) || print "Bail out!\n";
}

diag( "Testing RPC::Any::Interface::PSGI $RPC::Any::Interface::PSGI::VERSION, Perl $], $^X" );
