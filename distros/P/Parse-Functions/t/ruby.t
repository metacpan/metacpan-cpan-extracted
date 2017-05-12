#!/usr/bin/perl

# Tests the logic for extracting the list of functions in a Ruby program

use strict;
use warnings;
use Test::More;

plan( tests => 6 );

use Parse::Functions::Ruby ();

# Sample code we will be parsing
my $code = <<'END_RUBY';
=begin
def bogus(a, b):
=end
def initialize:
     return

def subtract(a, b):
     return a - b

def add(a, b):
     return a + b

def _private:
     return
END_RUBY

######################################################################
# Basic Parsing

SCOPE: {

	# Create the function list parser
	my $lf = new_ok(
		'Parse::Functions::Ruby',
	);

	# Check the result of the parsing
	is_deeply(
		[ $lf->find( $code ) ],
		[   qw{
				initialize
				subtract
				add
				_private
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
		'Parse::Functions::Ruby',
	);

	# Check the result of the parsing
	is_deeply(
		[ $lf->find( $code, 'alphabetical' ) ],
		[   qw{
				add
				initialize
				_private
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
		'Parse::Functions::Ruby',
	);

	# Check the result of the parsing
	is_deeply(
		[ $lf->find( $code, 'alphabetical_private_last' ) ],
		[   qw{
				add
				initialize
				subtract
				_private
				}
		],
		'Found expected functions (alphabetical_private_last)',
	);
}
