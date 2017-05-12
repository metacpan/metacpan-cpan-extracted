#!/usr/bin/perl

# Compile testing for Mirror::YAML

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 9;
use File::Spec::Functions ':ALL';
use Mirror::JSON;
use LWP::Online 'online';

# Basic construction
my $simple_file = catfile('t', 'data', 'simple.json');
ok( -f $simple_file, "Found test file" );
my $simple_conf = Mirror::JSON->read($simple_file);
isa_ok( $simple_conf, 'Mirror::JSON' );
is( $simple_conf->name, 'Comprehensive C Archive Network', '->name ok' );
isa_ok( $simple_conf->uri, 'URI' );
is( $simple_conf->timestamp, 1168895872, '->timestamp ok' );
ok( $simple_conf->age, '->age ok' );





# Fetch URIs
SKIP: {
	skip("Not online", 3) unless online;
	my $rv = $simple_conf->check_mirrors;
	ok( $rv, '->get_all ok' );

	# Get some mirrors
	my @m = $simple_conf->select_mirrors;
	ok( scalar(@m), 'Got at least 1 mirror' );
	isa_ok( $m[0], 'URI', 'Got at least 1 URI object' );
}
