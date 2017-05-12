#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib 'lib';

plan tests => 1;

BEGIN {
    use_ok( 'MzML::Parser' ) || print "Bail out!\n";
}

diag( "Testing MzML::Parser $MzML::Parser::VERSION, Perl $], $^X" );
