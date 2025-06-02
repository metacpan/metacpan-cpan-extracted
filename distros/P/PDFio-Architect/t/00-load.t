#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'PDFio::Architect' ) || print "Bail out!\n";
}

diag( "Testing PDFio::Architect $PDFio::Architect::VERSION, Perl $], $^X" );
