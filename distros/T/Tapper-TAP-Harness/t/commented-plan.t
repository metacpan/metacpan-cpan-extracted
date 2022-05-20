#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Tapper::TAP::Harness;
use File::Slurp 'slurp';
use Data::Dumper;

my $tap = slurp ("t/commented-plan.tap");

# ============================================================
#
#  Check whether section name with only dot works correctly
#
# ============================================================


my $harness = new Tapper::TAP::Harness( tap => $tap );

$harness->evaluate_report();


is(scalar(@{$harness->parsed_report->{tap_sections}}), 1, "section count");
is($harness->parsed_report->{tap_sections}->[0]->{section_name}, 'testrun-foo', "first section name");

done_testing;
