#!/usr/bin/perl
use strict; use warnings;

my $numtests;
BEGIN {
	$numtests = 1;

	eval "use Test::NoWarnings";
	if ( ! $@ ) {
		# increment by one
		$numtests++;
	}
}

use Test::More tests => $numtests;

use_ok( 'POE::Loop::Glib' );
