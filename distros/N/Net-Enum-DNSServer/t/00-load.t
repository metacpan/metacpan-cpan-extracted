#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Net::Enum::DNSServer' ) || print "Bail out!\n";
    use_ok( 'Net::Enum::DNS' ) || print "Bail out!\n";
}

diag( "Testing Net::Enum::DNSServer $Net::Enum::DNSServer::VERSION, Perl $], $^X" );
