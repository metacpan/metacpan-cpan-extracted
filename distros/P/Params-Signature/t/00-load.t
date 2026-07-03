#!perl 
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Params::Signature' ) || print "Bail out!\n";
    use_ok( 'Params::Signature::Multi' ) || print "Bail out!\n";
}

diag( "Testing Params::Signature $Params::Signature::VERSION, Perl $], $^X" );
