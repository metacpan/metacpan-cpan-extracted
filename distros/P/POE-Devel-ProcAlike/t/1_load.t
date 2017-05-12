#!/usr/bin/perl
use strict; use warnings;

my $numtests;
BEGIN {
	$numtests = 4;

	eval "use Test::NoWarnings";
	if ( ! $@ ) {
		# increment by one
		$numtests++;

	}
}

use Test::More tests => $numtests;

use_ok( 'POE::Devel::ProcAlike::PerlInfo' );
use_ok( 'POE::Devel::ProcAlike::ModuleInfo' );
use_ok( 'POE::Devel::ProcAlike::POEInfo' );
use_ok( 'POE::Devel::ProcAlike' );
