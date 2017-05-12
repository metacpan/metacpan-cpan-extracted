#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Params::Dry::Declare' ) || print "Bail out!\n";
}

diag( "Testing Params::Dry::Declare $Params::Dry::Declare::VERSION, Perl $], $^X" );
