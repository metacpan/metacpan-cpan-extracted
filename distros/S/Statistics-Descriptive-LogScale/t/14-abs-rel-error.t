#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Statistics::Descriptive::LogScale;

my $stat = Statistics::Descriptive::LogScale->new(
	linear_width => 1, base => 1.02
);

# Now try to add some data and see whether our class can distinguish
# between points.
$stat->add_data(-50..50);
my $raw = $stat->get_data_hash;
my @duplicate = grep { $raw->{$_} > 1 } sort { $a <=> $b } keys %$raw;
is (scalar @duplicate, 0, "No duplicates in raw bucket data (linear)")
	or diag "Duplicated entries: @duplicate";
note "The hash was: ", explain($raw);

$stat->clear;

# Now try to add log data, let's see if that makes different points

$stat->add_data(map { 100 * 1.0201 ** $_ } 1..500 ); # be careful - 1.02 fails
$raw = $stat->get_data_hash;
@duplicate = grep { $raw->{$_} > 1 } sort { $a <=> $b } keys %$raw;
is (scalar @duplicate, 0, "No duplicates in raw bucket data (log)")
	or diag "Duplicated entries: @duplicate";
# note "The hash was: ", explain($raw);


done_testing;

