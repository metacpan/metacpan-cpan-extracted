#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 13;
use File::Spec::Functions ':ALL';
use Perl::Metrics2;

my $file = rel2abs(catfile('t', 'data', 'hello.pl'));
ok( -f $file, "Found test file $file" );

# Clear all existing data from the database
ok(
	Perl::Metrics2::FileMetric->truncate,
	'->truncate ok',
);
is(
	Perl::Metrics2::FileMetric->count, 0,
	'->count returns zero',
);

# Process the sample file
ok(
	Perl::Metrics2->new->process_file($file),
	'->process_file ok',
);
is(
	Perl::Metrics2::FileMetric->count, 6,
	'->count returns correctly',
);
my @rows = Perl::Metrics2::FileMetric->select;
is( scalar(@rows), 6, 'Returned three rows' );
foreach ( @rows ) {
	isa_ok( $_, 'Perl::Metrics2::FileMetric' );
}

# Check the plugin study functionality
my $core = new_ok( 'Perl::Metrics2::Plugin::Core', [] );
