#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Tapper::TAP::Harness;
use File::Slurp 'slurp';
use Data::Dumper;

my $tap = slurp ("t/backcompat/tap_archive_much_whitespace.tap");

plan tests => 12;

# ============================================================

my $harness = new Tapper::TAP::Harness( tap => $tap );

$harness->evaluate_report();

is(scalar @{$harness->parsed_report->{tap_sections}}, 11, "count sections");
#diag Dumper($harness->parsed_report->{tap_sections});

my $first_section = $harness->parsed_report->{tap_sections}->[0];
#print STDERR Dumper($harness);

is($harness->parsed_report->{report_meta}{'suite-name'},    'Artemis-CTCS',             "report meta suite name");
is($harness->parsed_report->{report_meta}{'suite-version'}, '0.2',                      "report meta suite version");
is($harness->parsed_report->{report_meta}{'machine-name'},  'rhel5u2.64bit',            "report meta machine name");
is($harness->parsed_report->{report_meta}{'starttime-test-program'}, '20081028T135316', "report meta starttime test program");

is($first_section->{section_name},'artemis-meta-information', "first section name");

is($first_section->{section_meta}{'suite-name'},             'Artemis-CTCS', "report meta suite name");
is($first_section->{section_meta}{'suite-version'},          '0.2',          "report meta suite version");

# ============================================================

$tap     = slurp ("t/backcompat/tap_archive_sections_with_whitespace.tap");
$harness = new Tapper::TAP::Harness( tap => $tap );
$harness->evaluate_report();

is(scalar @{$harness->parsed_report->{tap_sections}}, 11, "count sections");

#print STDERR Dumper([ map { $_->{section_name} } @{$harness->parsed_report->{tap_sections}}]);

my $ctcs_section = $harness->parsed_report->{tap_sections}->[7];
is ($ctcs_section->{section_name}, 'CTCS-results', "ensure whitespace to dash in section name");

# ============================================================

$tap = slurp ("t/backcompat/tap_archive_kernbench.tap");
$harness = new Tapper::TAP::Harness( tap => $tap );
$harness->evaluate_report();
#diag Dumper($harness->parsed_report->{tap_sections});
is( scalar @{$harness->parsed_report->{tap_sections}}, 13, "kernbench section name interrupts-before count");
my $interrupts_before_section = $harness->parsed_report->{tap_sections}->[1];
is ($interrupts_before_section->{section_name}, 'stats-proc-interrupts-before', "kernbench section name interrupts-before");

# ============================================================
