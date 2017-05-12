#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN {
    use_ok( 'NET::MitM' ) || print "Bail out!\n";
}

diag( "Testing NET::MitM $NET::MitM::VERSION, Perl $], $^X" );
