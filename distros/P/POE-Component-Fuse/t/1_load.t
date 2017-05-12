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

use_ok( 'POE::Component::Fuse' );
use_ok( 'POE::Component::Fuse::SubProcess' );
use_ok( 'POE::Component::Fuse::AsyncFsV' );
use_ok( 'POE::Component::Fuse::myFuse' );
