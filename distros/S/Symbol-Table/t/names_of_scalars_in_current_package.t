#!/usr/local/bin/perl

	# get the names of all scalars in the current package
	package MyPackage;

	use Data::Dumper;

use Test::More tests => 2;
BEGIN { use_ok('Symbol::Table') };

	our $our_scalar=0; $our_scalar++;

	my $st = Symbol::Table->New('SCALAR');

	my @actual;

	foreach my $scalar (keys(%$st))
		{
		push(@actual,$scalar);
		}

	my @expected = 
		(
        	  'our_scalar'
        	);

	is($actual,$expected,
		"confirm we can get names of all scalar package vars");