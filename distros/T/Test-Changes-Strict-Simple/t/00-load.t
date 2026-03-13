#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Test::Changes::Strict::Simple' ) || print "Bail out!\n";
}

diag( "Testing Test::Changes::Strict::Simple $Test::Changes::Strict::Simple::VERSION, Perl $], $^X" );
