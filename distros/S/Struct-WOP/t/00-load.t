#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Struct::WOP' ) || print "Bail out!\n";
}

diag( "Testing Struct::WOP $Struct::WOP::VERSION, Perl $], $^X" );
