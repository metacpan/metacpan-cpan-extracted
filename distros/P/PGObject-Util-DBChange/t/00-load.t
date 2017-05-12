#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'PGObject::Util::DBChange' ) || print "Bail out!\n";
}

diag( "Testing PGObject::Util::DBChange $PGObject::Util::DBChange::VERSION, Perl $], $^X" );
