#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojo::DOM::Role::Restrict' ) || print "Bail out!\n";
}

diag( "Testing Mojo::DOM::Role::Restrict $Mojo::DOM::Role::Restrict::VERSION, Perl $], $^X" );
