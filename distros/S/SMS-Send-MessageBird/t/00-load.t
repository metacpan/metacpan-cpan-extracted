#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'SMS::Send::MessageBird' ) || print "Bail out!\n";
}

diag( "Testing SMS::Send::MessageBird $SMS::Send::MessageBird::VERSION, Perl $], $^X" );
