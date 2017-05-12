#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Tapper::TAP::Harness;
use File::Slurp 'slurp';
use Data::Dumper;

my $tap = slurp ("t/tap_archive_mini.tap");

plan tests => 8;

# ============================================================

my $harness = new Tapper::TAP::Harness( tap => $tap );

$harness->evaluate_report();

is(scalar @{$harness->parsed_report->{tap_sections}}, 1, "count sections");

my $first_section = $harness->parsed_report->{tap_sections}->[0];

is($harness->parsed_report->{report_meta}{'suite-name'},    'unknown',                  "report meta suite name");
is($harness->parsed_report->{report_meta}{'suite-version'}, 'unknown',                  "report meta suite version");

is($first_section->{section_name},                  'section-000', "first section name");

# ============================================================

$tap = slurp ("t/tap_archive_mini_version.tap");
$harness = new Tapper::TAP::Harness( tap => $tap );

$harness->evaluate_report();

is(scalar @{$harness->parsed_report->{tap_sections}}, 1, "count sections");

$first_section = $harness->parsed_report->{tap_sections}->[0];

is($harness->parsed_report->{report_meta}{'suite-name'},    'unknown',                  "report meta suite name");
is($harness->parsed_report->{report_meta}{'suite-version'}, 'unknown',                  "report meta suite version");

is($first_section->{section_name},                  'section-000', "first section name");

# ============================================================

