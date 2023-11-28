#!perl
use 5.034;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'PGObject::Util::LogRep::TestDecoding' ) || print "Bail out!\n";
}

diag( "Testing PGObject::Util::LogRep::TestDecoding $PGObject::Util::LogRep::TestDecoding::VERSION, Perl $], $^X" );
