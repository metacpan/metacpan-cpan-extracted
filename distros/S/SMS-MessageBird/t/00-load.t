#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'SMS::MessageBird' ) || print "Bail out!\n";
}

diag( "Testing SMS::MessageBird $SMS::MessageBird::VERSION, Perl $], $^X" );
