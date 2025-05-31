#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'PDFio::FFI' ) || print "Bail out!\n";
}

diag( "Testing PDFio::FFI $PDFio::FFI::VERSION, Perl $], $^X" );
