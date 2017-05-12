#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Params::Dry' ) || print "Bail out!\n";
    use_ok( 'Params::Dry::Types' ) || print "Bail out!\n";
}

diag( "Testing Params::Dry $Params::Dry::VERSION, Perl $], $^X" );
