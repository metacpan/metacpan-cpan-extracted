#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::IANA::TLD' ) || print "Bail out!\n";
}

diag( "Testing Net::IANA::TLD $Net::IANA::TLD::VERSION, Perl $], $^X" );
