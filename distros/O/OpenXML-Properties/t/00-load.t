#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'OpenXML::Properties' ) || print "Bail out!\n";
}

diag( "Testing OpenXML::Properties $OpenXML::Properties::VERSION, Perl $], $^X" );
