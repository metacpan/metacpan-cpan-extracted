#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::Whois::RIS' ) || print "Bail out!";
}

diag( "Testing Net::Whois::RIS $Net::Whois::RIS::VERSION, Perl $], $^X" );
