#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'SMS::API::CMTelecom' ) || print "Bail out!\n";
}

diag( "Testing SMS::API::CMTelecom $SMS::API::CMTelecom::VERSION, Perl $], $^X" );
