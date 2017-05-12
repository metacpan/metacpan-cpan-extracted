#!/usr/bin/perl

# Don't download 100meg just to install the module

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

plan( tests => 2 );

ok( $] >= 5.008005, 'Perl version is new enough' );

use_ok( 'ORDB::CPANTS' );
