#!/usr/bin/perl

# Tests the logic for extracting the list of functions in a program

use strict;
use warnings;
use Test::More;

plan( tests => 6 );

use Parse::Functions::Perl ();

# Sample code we will be parsing
my $code = <<'END_PERL';
package Foo;
sub _bar { }
sub foo1 {}
sub foo3 { }
sub foo2{}
sub  foo4 {
}
sub foo5 :tag {
}
*backwards = sub { };
*_backwards = \&backwards;
END_PERL





######################################################################
# Basic Parsing

SCOPE: {

	# Create the function list parser
	my $lf = new_ok(
		'Parse::Functions::Perl',
	);

	# Check the result of the parsing
	is_deeply(
		[ $lf->find($code) ],
		[   qw{
				_bar
				foo1
				foo3
				foo2
				foo4
				foo5
				backwards
				_backwards
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
		'Parse::Functions::Perl',
	);

	# Check the result of the parsing
	is_deeply(
		[ $lf->find($code, 'alphabetical') ],
		[   qw{
				backwards
				_backwards
				_bar
				foo1
				foo2
				foo3
				foo4
				foo5
				}
		],
		'Found expected functions alphabetical',
	);
}





######################################################################
# Alphabetical Ordering (Private Last)

SCOPE: {

	# Create the function list parser
	my $lf = new_ok(
		'Parse::Functions::Perl',
	);

	# Check the result of the parsing
	is_deeply(
		[ $lf->find($code, 'alphabetical_private_last') ],
		[   qw{
				backwards
				foo1
				foo2
				foo3
				foo4
				foo5
				_backwards
				_bar
				}
		],
		'Found expected functions alphabetical_private_last',
	);
}
