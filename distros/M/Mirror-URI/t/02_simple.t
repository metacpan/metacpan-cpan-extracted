#!/usr/bin/perl

# Compile testing for Mirror::YAML

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 14;
use File::Spec::Functions ':ALL';
use Mirror::YAML;

my $dir  = catdir('t', 'data', 'simple');
my $file = catfile($dir, 'mirror.yml');
ok( -d $dir,  'Found test directory' );
ok( -f $file, 'Found test file'      );

# Load the mirror
my $mirror = Mirror::YAML->read($dir);
isa_ok( $mirror, 'Mirror::YAML' );
is( $mirror->name, 'JavaScript Archive Network', '->name ok' );
isa_ok( $mirror->master, 'URI::http' );
is( scalar($mirror->mirrors), 14, 'Got 14 mirrors' );
is( $mirror->filename, 'mirror.yml', '->offset' );

# Check the timing numbers
my $number = qr/^\d+\.\d*$/;
is( $mirror->timestamp, 1168895872, '->timestamp ok' );
like( $mirror->lastget, $number,    '->lastget ok'   );
like( $mirror->lag,     $number,    '->lag ok'       );
like( $mirror->age,     $number,    '->age ok'       );
is(
	$mirror->as_string,
	$mirror->uri->as_string,
	'->as_string returns as expected',
);
ok(   $mirror->is_cached, '->is_cached ok' );
ok( ! $mirror->is_master, '->is_master ok' );
