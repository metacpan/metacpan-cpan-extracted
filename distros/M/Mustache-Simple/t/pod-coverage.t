#!perl -T
use 5.10.0;
use strict;
use warnings FATAL => 'all';
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

plan tests => 1;

    pod_coverage_ok('Mustache::Simple',
	{
	    also_private => [
		qr/^dottags$/,
		qr/^escape$/,
		qr/^getfile$/,
		qr/^include_partial$/,
		qr/^match_template$/,
		qr/^pop$/,
		qr/^push$/,
		qr/^reassemble$/,
		qr/^resolve$/,
		qr/^tag_match$/,
		qr/^find$/,
	    ],
	    trustme => [ ]
	}
    );
