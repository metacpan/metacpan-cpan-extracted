#!/usr/bin/perl

# Tests the logic for extracting the list of functions in a Python program

use strict;
use warnings;
use Test::More;

plan( tests => 6 );

use Parse::Functions::Python ();

# Sample code we will be parsing
my $code = <<'END_PYTHON';
"""
def bogus(a, b):
"""
def __init__:
     return

def subtract(a, b):
     return a - b

def add(a, b):
     return a + b

g = lambda x: x**2
END_PYTHON

######################################################################
# Basic Parsing

SCOPE: {

	# Create the function list parser
	my $lf = new_ok(
		'Parse::Functions::Python',
	);

	# Check the result of the parsing
	is_deeply(
		[ $lf->find( $code ) ],
		[   qw{
				__init__
				subtract
				add
				g
				}
		],
		'Found expected functions',
	);
}





######################################################################
# Alphabetical Ordering

SCOPE: {

	# Create the function list parser
	my $lf = new_ok(
		'Parse::Functions::Python',
	);

	# Check the result of the parsing
	is_deeply(
		[ $lf->find( $code, 'alphabetical' ) ],
		[   qw{
				add
				g
				__init__
				subtract
				}
		],
		'Found expected functions (alphabetical)',
	);
}





######################################################################
# Alphabetical Ordering (Private Last)

SCOPE: {

	# Create the function list parser
	my $lf = new_ok(
		'Parse::Functions::Python',
	);

	# Check the result of the parsing
	is_deeply(
		[ $lf->find( $code, 'alphabetical_private_last' ) ],
		[   qw{
				add
				g
				subtract
				__init__
				}
		],
		'Found expected functions (alphabetical_private_last)',
	);
}
