#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Net::OpenVPN::Launcher' ) || print "Bail out!\n";
}

diag( "Testing Net::OpenVPN::Launcher $Net::OpenVPN::Launcher::VERSION, Perl $], $^X" );
