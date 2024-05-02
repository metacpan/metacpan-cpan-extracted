#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Super::Powers' ) || print "Bail out!\n";
}

diag( "Testing Super::Powers $Super::Powers::VERSION, Perl $], $^X" );
