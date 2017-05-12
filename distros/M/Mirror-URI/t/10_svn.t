#!/usr/bin/perl

# Compile testing for Mirror::YAML

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use LWP::Online ':skip_all';
use Test::More tests => 19;
use File::Spec::Functions ':ALL';
use Mirror::YAML ();

my $test_dir  = catdir('t', 'data', 'svn1');
my $test_file = catfile($test_dir, 'mirror.yml');
ok( -d $test_dir,  'Found test directory' );
ok( -f $test_file, 'Found test file'      );





#####################################################################
# Local Half

# Load the mirror
my $mirror = Mirror::YAML->read($test_dir);
isa_ok( $mirror, 'Mirror::YAML' );
is( $mirror->version, '1.0', '->version ok' );
is( $mirror->name, 'SVN Test Repository', '->name ok' );
isa_ok( $mirror->master, 'URI::http' );

# Check the timing numbers
my $number = qr/^\d+\.\d*$/;
is( $mirror->timestamp, 1220649472, '->timestamp ok' );
like( $mirror->lastget, $number,    '->lastget ok'   );
like( $mirror->lag,     $number,    '->lag ok'       );
like( $mirror->age,     $number,    '->age ok'       );





#####################################################################
# Online Half

# Pull the master
my $master = $mirror->get_master;
isa_ok( $master, 'Mirror::YAML' );
is( $master->valid, 1, '->valid ok' );
isa_ok( $mirror->{master}, 'Mirror::YAML' );
is(
	$mirror->version,
	$master->version,
	'->version matches',
);
is(
	$mirror->name,
	$master->name,
	'->name matches',
);
is_deeply(
	$mirror->master->uri,
	$master->uri,
	'->master matches',
);

# Pull a mirror
my $mirror0 = $mirror->get_mirror(0);
isa_ok( $mirror0, 'Mirror::YAML' );
is( $mirror0->valid, 1, '->valid ok' );
isa_ok( $mirror->{mirrors}->[0], 'Mirror::YAML' );
