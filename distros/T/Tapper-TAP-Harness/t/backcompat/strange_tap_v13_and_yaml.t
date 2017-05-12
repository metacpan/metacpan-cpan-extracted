#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Tapper::TAP::Harness;
use File::Slurp 'slurp';
use Data::Dumper;

my $tap;
my $harness;
my $interrupts_before_section;

# ============================================================

$tap = slurp ("t/backcompat/tap_archive_kernbench_no_v13.tap");
$harness = new Tapper::TAP::Harness( tap => $tap );
$harness->evaluate_report();
#print STDERR Dumper($harness->parsed_report->{tap_sections});
is( scalar @{$harness->parsed_report->{tap_sections}}, 15, "kernbench_no_v13 section name interrupts-before count");
$interrupts_before_section = $harness->parsed_report->{tap_sections}->[1];
is ($interrupts_before_section->{section_name}, 'stats-proc-interrupts-before', "kernbench_no_v13 section name interrupts-before");

# ============================================================

$tap     = slurp ("t/backcompat/tap_archive_kernbench2.tap");
$harness = new Tapper::TAP::Harness( tap => $tap );
$harness->evaluate_report();
#print STDERR Dumper($harness->parsed_report->{tap_sections});
is( scalar @{$harness->parsed_report->{tap_sections}}, 15, "kernbench2 section name interrupts-before count");
$interrupts_before_section = $harness->parsed_report->{tap_sections}->[1];
is ($interrupts_before_section->{section_name}, 'stats-proc-interrupts-before', "kernbench2 section name interrupts-before");


# ============================================================

$tap = slurp ("t/backcompat/tap_archive_missing_yaml.tap");
$harness = new Tapper::TAP::Harness( tap => $tap );
$harness->evaluate_report();
#print STDERR Dumper($harness->parsed_report->{tap_sections});
is( scalar @{$harness->parsed_report->{tap_sections}}, 2, "section count");
my $stuff = $harness->parsed_report->{tap_sections}->[1];
is ($stuff->{section_name}, 't/artemis_reports_dpath', "section name");
like ($stuff->{raw}, qr/count ALL plans/ms, "section contains known description 1");
like ($stuff->{raw}, qr/allow easier/ms, "section contains known description 2");
like ($stuff->{raw}, qr/foo: bar/ms, "section contains yaml 1");
like ($stuff->{raw}, qr/affe: zomtec/ms, "section contains yaml 2");
my $html = $harness->generate_html();
done_testing();
