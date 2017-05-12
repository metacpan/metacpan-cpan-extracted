#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::DNSBL::Client' ) || print "Bail out!
";
}

diag( "Testing Net::DNSBL::Client $Net::DNSBL::Client::VERSION, Perl $], $^X" );
