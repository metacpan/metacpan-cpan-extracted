#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Tapper::TAP::Harness;
use File::Slurp 'slurp';
use Data::Dumper;

my $tap = slurp ("t/dot_section.tap");

plan tests => 5;

# ============================================================
#
#  Check whether section name with only dot works correctly
#
# ============================================================


my $harness = new Tapper::TAP::Harness( tap => $tap );

$harness->evaluate_report();


is($harness->parsed_report->{tap_sections}->[0]->{section_name}, '.', "first section name");
# If the following test fails we get an exception.
SKIP: { skip "that test seems to trigger linux-specific behavior", 2;
like($harness->generate_html, qr'_dot_</a>', q(Generate HTML for TAP with section names that lead to illegal file names));
like($harness->generate_html, qr'some.section</a>', q(Generate HTML for TAP with section names that contain dots but don't lead to illegal file names));
}

# check empty Tapper-section:
is($harness->parsed_report->{tap_sections}->[2]->{section_name}, 'section-002', "empty section name");
is($harness->parsed_report->{tap_sections}->[3]->{section_name}, 'section-003', "empty section name");
