#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
	use lib 'lib';
	use_ok( 'Parse::Gnaw' ) || print "Bail out!\n";
}

diag( "Testing Parse::Gnaw $Parse::Gnaw::VERSION, Perl $], $^X" );


