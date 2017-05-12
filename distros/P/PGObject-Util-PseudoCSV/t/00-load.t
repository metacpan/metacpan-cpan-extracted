#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'PGObject::Util::PseudoCSV' ) || print "Bail out!\n";
}

diag( "Testing PGObject::Util::PseudoCSV $PGObject::Util::PseudoCSV::VERSION, Perl $], $^X" );
