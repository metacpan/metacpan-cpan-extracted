#!perl -T

use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Struct::Path::JsonPointer' ) || print "Bail out!\n";
}

diag( "Testing Struct::Path::JsonPointer $Struct::Path::JsonPointer::VERSION, Perl $], $^X" );
