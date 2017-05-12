#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'SemMed::Interface' ) || print "Bail out!\n";
}

diag( "Testing SemMed::Interface $SemMed::Interface::VERSION, Perl $], $^X" );
