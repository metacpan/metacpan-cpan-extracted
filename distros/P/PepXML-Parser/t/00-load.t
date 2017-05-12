#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;
use lib "lib";

plan tests => 1;

BEGIN {
    use_ok( 'PepXML::Parser' ) || print "Bail out!\n";
}

diag( "Testing PepXML::Parser $PepXML::Parser::VERSION, Perl $], $^X" );
