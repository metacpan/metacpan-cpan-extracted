#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Tapper::TAP::Harness;
use File::Slurp 'slurp';
use Data::Dumper;
use Test::Deep;

plan tests => 5;

my $tap;
my $harness;
my $interrupts_before_section;

# ============================================================

$tap     = slurp ("t/backcompat/tap_archive_rhv7.tap");
$harness = new Tapper::TAP::Harness( tap => $tap );
$harness->evaluate_report();

#print STDERR Dumper($harness->parsed_report->{tap_sections});
# foreach (map { $_->{section_name} }  @{$harness->parsed_report->{tap_sections}})
# {
#         diag "Section: $_";
# }

is( scalar @{$harness->parsed_report->{tap_sections}}, 12, "rhv7 section count");
cmp_deeply ([ map { $_->{section_name} } @{$harness->parsed_report->{tap_sections}}],
            [
             qw/
                       section-000
                       artemis-meta-information
                       section-002
                       stats-proc-interrupts-before
                       section-004
                       rhv7-run
                       RHV7-results
                       dmesg
                       var_log_messages
                       stats-proc-interrupts-after
                       clocksource
                       uptime
               /
            ],
         "tap sections");

my $metainfo = $harness->parsed_report->{tap_sections}->[10];
is ($metainfo->{section_name}, 'clocksource', "rhv7 section name Clocksource");
like ($metainfo->{raw}, qr/Clocksource: jiffies/, "Clocksource raw contains YAML");

like ($harness->parsed_report->{tap_sections}->[11]->{raw}, qr/uptime: 162884s/, "uptime raw contains YAML");

