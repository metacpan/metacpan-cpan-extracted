#!/usr/bin/perl

# Don't download 10meg just to install the module

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use LWP::Online ':skip_all';
unless ( $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
	exit(0);
}

plan( tests => 1 );

use_ok( 'ORDB::CPANMeta' );
