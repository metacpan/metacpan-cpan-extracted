#!/usr/bin/perl

# Don't download stuff just to install the module

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use Params::Util ();
use LWP::Online ':skip_all';
unless ( $ENV{RELEASE_TESTING} ) {
	plan( skip_all => "Author tests not required for installation" );
	exit(0);
}

plan tests => 3;

use_ok( 'ORDB::CPANRT' );

my $latest = ORDB::CPANRT->latest;
ok( $latest, 'Got latest record' );

my $age = ORDB::CPANRT->age;
ok(
	defined Params::Util::_NONNEGINT($age),
	'Got non-negative integer for ->age',
);
