#!perl -T
use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    use_ok( 'PGObject' ) || print "Bail out!\n";
    use_ok( 'PGObject::Util::DBException' ) || print "Bail out!\n";
}

diag( "Testing PGObject $PGObject::VERSION, Perl $], $^X" );
