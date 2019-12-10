#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Mojo::Firewall' ) || print "Bail out!\n";
}

diag( "Testing Mojo::Firewall $Mojo::Firewall::VERSION, Perl $], $^X" );
