#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Remember::Anything::AsPath' ) || print "Bail out!\n";
}

diag( "Testing Remember::Anything::AsPath $Remember::Anything::AsPath::VERSION, Perl $], $^X" );
