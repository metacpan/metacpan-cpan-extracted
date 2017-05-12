#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Tapper::TAP::Harness;
use File::Slurp 'slurp';
use Data::Dumper;

# ==================================================== #
# Test whether single lazy test plans without explicit #
# section start headers work correctly.                #
# ==================================================== #


my $tap = slurp ("t/tap_archive_tapper_single_lazy_plan.tap");


plan tests => 1;

my $harness = new Tapper::TAP::Harness( tap => $tap );

$harness->evaluate_report();

is(scalar @{$harness->parsed_report->{tap_sections}}, 1, "count sections");

