#!/usr/bin/perl

use strict;
use Test;
BEGIN { plan tests => 3, todo => [] }

use String::Escape qw( printable unprintable escape );

{
	my ( $original, $printable, $comparison );

	# Backslash escapes for newline and tab characters

	$original = "\tNow is the time\nfor all good folk\nto party.\n";
	$comparison = '\\tNow is the time\\nfor all good folk\\nto party.\\n';

	ok( escape('qprintable', $original) eq '"' . $comparison . '"' );
}

{
	# Can pass in function references

	my $running_total;
	my @results = escape( sub { $running_total += shift; }, 23, 4, 2, 13 );
	ok( $results[3] == 42 );
}

{ 
	eval {
		escape( 'no-such-escape-style', 'foobar' )
	};
	ok( $@ )
}
