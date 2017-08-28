#!perl -T
use strict;
use warnings;

use Test::More tests => 1;

BEGIN {
    use_ok( 'PGObject' ) || print "Bail out!\n";
}

diag( "Testing PGObject $PGObject::VERSION, Perl $], $^X" );
