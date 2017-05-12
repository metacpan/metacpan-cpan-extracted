#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::LDAP::SID' ) || print "Bail out!\n";
}

diag( "Testing Net::LDAP::SID $Net::LDAP::SID::VERSION, Perl $], $^X" );
