#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::Cloudflare::DNS' ) || print "Bail out!\n";
}

diag( "Testing Net::Cloudflare::DNS $Net::Cloudflare::DNS::VERSION, Perl $], $^X" );
