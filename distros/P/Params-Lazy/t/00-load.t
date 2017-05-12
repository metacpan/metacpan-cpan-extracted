#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Params::Lazy' ) || print "Bail out!\n";
}

diag( "Testing Params::Lazy $Params::Lazy::VERSION, Perl $], $^X" ) unless caller;
