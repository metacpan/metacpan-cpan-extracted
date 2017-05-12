#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 1;

BEGIN {
    use_ok( 'SMS::API::QuickTelecom' ) || print "Bail out!\n";
}

#diag( "Testing SMS::API::QuickTelecom $SMS::API::QuickTelecom::VERSION, Perl $], $^X" );
