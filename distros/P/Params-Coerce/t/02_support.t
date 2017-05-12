#!/usr/bin/perl -w

# Support method testing for Params::Coerce

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;
use Params::Coerce ();





#####################################################################
# Begin testing support methods

# Test _loaded
ok(   Params::Coerce::_loaded('Params::Coerce'), '_loaded returns true for Params::Coerce' );
ok( ! Params::Coerce::_loaded('Params::Coerce::Bad'), '_loaded returns false for Params::Coerce::Bad' );

# Test _function_exists
ok(   Params::Coerce::_function_exists('Params::Coerce', '_function_exists'), '_function_exists sees itself' );
ok( ! Params::Coerce::_function_exists('Foo', 'bar'), '_function_exists doesn\' see non-existant function' );
ok( ! Params::Coerce::_function_exists('Params::Coerce', 'VERSION'),
	'_function_exists does not return true for other variable types' );

exit(0);
