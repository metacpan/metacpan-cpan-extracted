#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'SMS::Send::Iletimerkezi' ) || print "Bail out!\n";
}

diag( "Testing SMS::Send::Iletimerkezi $SMS::Send::Iletimerkezi::VERSION, Perl $], $^X" );
