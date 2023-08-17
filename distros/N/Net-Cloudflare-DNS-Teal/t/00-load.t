#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Cloudflare::DNS::Teal' ) || print "Bail out!\n";
}

diag( "Testing Net::Cloudflare::DNS::Teal $Net::Cloudflare::DNS::Teal::VERSION, Perl $], $^X" );
