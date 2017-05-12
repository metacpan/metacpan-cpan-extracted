#!/usr/bin/perl

# Test the export behaviour of POE::Declare

use strict;
use warnings;
BEGIN {
	$|  = 1;
}

use Test::More tests => 7;
use Test::NoWarnings;

# Check that "use POE::Declare;" acts as an implicit "use POE;"
is( defined(&ARG0), '', 'ARG0 is not defined before "use POE::Declare"' );
use_ok( "POE::Declare" );
ok( $POE::VERSION,          '$POE::VERSION ok'          );
ok( $POE::Session::VERSION, '$POE::Session::VERSION ok' );
ok( eval("ARG0"), 'ARG0 is defined' );
is( eval("ARG0"), eval("POE::Session::ARG0"), 'ARG0 is correct' );
