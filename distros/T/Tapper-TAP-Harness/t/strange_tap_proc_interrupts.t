#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Tapper::TAP::Harness;
use File::Slurp 'slurp';
use Data::Dumper;
use Test::Deep;

plan tests => 12;

my $tap;
my $harness;
my $interrupts_before_section;

# ============================================================

$tap     = slurp ("t/tap_archive_kernbench4.tap");
$harness = new Tapper::TAP::Harness( tap => $tap );
$harness->evaluate_report();

#print STDERR Dumper($harness->parsed_report->{tap_sections});
# foreach (map { $_->{section_name} }  @{$harness->parsed_report->{tap_sections}})
# {
#         diag "Section: $_";
# }

is( scalar @{$harness->parsed_report->{tap_sections}}, 20, "kernbench4 section count");
cmp_bag ([ map { $_->{section_name} } @{$harness->parsed_report->{tap_sections}}],
         [
          qw/
                    tapper-meta-information
                    stats-proc-interrupts-before
                    kernel-untar
                    kernbench-untar
                    kernbench-testrun
                    section-005
                    kernbench-results
                    kernbench-testrun1
                    section-008
                    kernbench-results1
                    kernbench-testrun2
                    section-011
                    kernbench-results2
                    dmesg
                    var_log_messages
                    stats-proc-interrupts-after
                    clocksource
                    uptime
                    kernbench-results-2
                    clocksource-2
            /
         ],
         "tap sections");

$interrupts_before_section = $harness->parsed_report->{tap_sections}->[1];
is ($interrupts_before_section->{section_name}, 'stats-proc-interrupts-before', "kernbench4 section name interrupts-before");

like ($harness->parsed_report->{tap_sections}->[1]->{raw}, qr/linetail: IO-APIC-edge  timer/, "raw contains yaml");

#print STDERR Dumper($harness->parsed_report->{tap_sections}->[18]->{raw});
like ($harness->parsed_report->{tap_sections}->[18]->{raw}, qr/2.6.9-89.ELhugemem/, "raw contains kernel");

#print STDERR Dumper($harness->parsed_report->{tap_sections}->[19]->{raw});
like ($harness->parsed_report->{tap_sections}->[19]->{raw}, qr/Cannot_determine_clocksource: ~/, "raw contains clocksource yaml");

# ============================================================

$tap     = slurp ("t/tap_archive_kernbench5.tap");
$harness = new Tapper::TAP::Harness( tap => $tap );
$harness->evaluate_report();

#print STDERR Dumper($harness->parsed_report->{tap_sections});
# foreach (map { $_->{section_name} }  @{$harness->parsed_report->{tap_sections}})
# {
#         diag "Section: $_";
# }

is( scalar @{$harness->parsed_report->{tap_sections}}, 12, "kernbench5 section count");
cmp_bag ([ map { $_->{section_name} } @{$harness->parsed_report->{tap_sections}}],
         [
          qw/
                    tapper-meta-information
                    stats-proc-interrupts-before
                    kernel-untar
                    kernbench-untar
                    kernbench-testrun
                    kernbench-results
                    section-005
                    dmesg
                    var_log_messages
                    stats-proc-interrupts-after
                    clocksource
                    uptime
            /
         ],
         "tap sections");

$interrupts_before_section = $harness->parsed_report->{tap_sections}->[1];
is ($interrupts_before_section->{section_name}, 'stats-proc-interrupts-before', "kernbench5 section name interrupts-before");
like ($harness->parsed_report->{tap_sections}->[1]->{raw}, qr/linetail: IO-APIC-edge\s*timer/, "raw contains yaml");

# print STDERR Dumper($harness->parsed_report->{tap_sections}->[6]->{raw});
like ($harness->parsed_report->{tap_sections}->[6]->{raw}, qr/2.6.27.7-9-default/, "raw contains kernel");

# print STDERR Dumper($harness->parsed_report->{tap_sections}->[10]->{raw});
like ($harness->parsed_report->{tap_sections}->[10]->{raw}, qr/kvm-clock: ~/, "raw contains kvm-clock yaml");

