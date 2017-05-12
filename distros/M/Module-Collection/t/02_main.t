#!/usr/bin/perl -w

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$|  = 1;
	$^W = 1;
}


use Test::More tests => 14;
use Module::Collection;

my $sample_root = catdir( 't', 'dists' );
ok( -d $sample_root, "Found test collection at $sample_root" );





#####################################################################
# Test a simple collection

SCOPE: {
	my $collection = Module::Collection->new(
		root => $sample_root,
		);
	isa_ok( $collection, 'Module::Collection' );
	is( $collection->root, $sample_root, '->root, ok' );

	# Check distsr
	is( scalar($collection->dists), 3, '->dists returns 3 in scalar context' );
	is_deeply( [ $collection->dists ], [ qw{
		Config-Tiny-2.05.tar.gz
		Config-Tiny-2.09.tar.gz
		YAML-Tiny-0.10.tar.gz
		} ], '->dists returns list in list context' );

	# Get a dist
	ok( -f $collection->dist_path('Config-Tiny-2.05.tar.gz'), 'Found sample tarball' );
	my $dist = $collection->dist('Config-Tiny-2.05.tar.gz');
	isa_ok( $dist, 'Module::Inspector' );
	is( $dist->dist_name, 'Config-Tiny', 'Got correct dist name' );
	isa_ok( $dist->dist_version, 'version' );
	is( $dist->dist_version, '2.050', 'Got correct dist version' );

	# Ignore the older of the Config-Tiny releases
	ok( $collection->ignore_old_dists, '->ignore_old_dists ok' );
	is( scalar($collection->dists), 2, '->dists returns 2 in scalar context' );
	is_deeply( [ $collection->dists ], [ qw{
		Config-Tiny-2.09.tar.gz
		YAML-Tiny-0.10.tar.gz
		} ], '->dists returns only the newest dists' );

	# Get the combined dependencies of the remaining
	my $deps = $collection->depends;
	isa_ok( $deps, 'Module::Math::Depends' );
}

1;
