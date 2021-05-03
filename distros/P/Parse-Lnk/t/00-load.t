#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Parse::Lnk' ) || print "Bail out!\n";
}

diag( "Testing Parse::Lnk $Parse::Lnk::VERSION, Perl $], $^X" );
