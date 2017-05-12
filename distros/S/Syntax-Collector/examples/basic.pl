#!/usr/bin/env perl

# Define a syntax collection
#
BEGIN {
	package Syntax::Collector::Example;
	
	use 5.010;
	use Syntax::Collector q/
		use feature 0 ':5.10';
		use strict 0;
		use warnings 0;
	/;
	
	our @EXPORT = qw( maybe );
	
	sub maybe {
		return @_ if defined $_[0] && defined $_[1];
		shift; shift; return @_;
	}
}

package main;

# Import the collection
#
use Syntax::Collector::Example;

# The 'say' feature is enabled by the collection,
# and the 'maybe' function was exported.
#
say maybe(foo => 'bar');

# Warnings were enabled by the collection, so this
# should warn!
#
say undef;

