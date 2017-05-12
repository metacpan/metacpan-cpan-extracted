#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'PGObject::Util::DBMethod' ) || print "Bail out!\n";
}

diag( "Testing PGObject::Util::DBMethod $PGObject::Util::DBMethod::VERSION, Perl $], $^X" );
