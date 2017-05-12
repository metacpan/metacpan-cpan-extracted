#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::Squid::ReverseProxy' ) || print "Bail out!
";
}

diag( "Testing Net::Squid::ReverseProxy $Net::Squid::ReverseProxy::VERSION, Perl $], $^X" );
