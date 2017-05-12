#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Statistics::Descriptive::LogScale;

my @try_json = qw(JSON::XS JSON::PP);
my $json;

foreach (@try_json) {
	eval "require $_; 1" or next;
	$json = $_;
	last;
};

if (!$json) {
	plan SKIP_ALL => "No JSON module found, skipping serial test";
	exit;
};

# Setup serializer
# We want *_blessed for obvious reasons
# We also want canonical so that the keys get sorted
#     and we can compare strings
my $serial = $json->new->allow_blessed->convert_blessed->canonical;

my $stat = Statistics::Descriptive::LogScale->new();
$stat->add_data(0..5);

my $str = $serial->encode($stat);
note "str = $str";

my $stat2 = Statistics::Descriptive::LogScale->new(%{ $serial->decode($str) } );

is( $serial->encode($stat2), $str, "JSON round trip" );
done_testing;
