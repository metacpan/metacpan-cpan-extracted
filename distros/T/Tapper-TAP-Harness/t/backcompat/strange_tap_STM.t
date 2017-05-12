#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Tapper::TAP::Harness;
use File::Slurp 'slurp';
use Data::Dumper;
use Test::Deep;

my $tap;
my $harness;
my $interrupts_before_section;

# ============================================================
# the easy thing: no embedded YAML
# ============================================================

$tap     = slurp ("t/backcompat/tap_archive_STM_explicit_section_no_yaml.tap");
$harness = new Tapper::TAP::Harness( tap => $tap );
$harness->evaluate_report();

is( scalar @{$harness->parsed_report->{tap_sections}}, 1, "section count");
cmp_bag ([ map { $_->{section_name} } @{$harness->parsed_report->{tap_sections}}], [ qw/ section-000 / ], "tap sections");
my $html = $harness->generate_html();
unlike($html, qr/Parse error: More than one plan found in TAP output/, "no parse error: More than one plan found");
unlike($html, qr/Parse error: No plan found in TAP output/, "no parse error: No plan found");

# ============================================================
# the hard thing: embedded YAML
# ============================================================

$tap     = slurp ("t/backcompat/tap_archive_STM_explicit_section.tap");
$harness = new Tapper::TAP::Harness( tap => $tap );
$harness->evaluate_report();

is( scalar @{$harness->parsed_report->{tap_sections}}, 1, "section count");
cmp_bag ([ map { $_->{section_name} } @{$harness->parsed_report->{tap_sections}}], [ qw/ section-000 / ], "tap sections");
$html = $harness->generate_html();

unlike($html, qr/Parse error: More than one plan found in TAP output/, "no parse error: More than one plan found");
unlike($html, qr/Parse error: No plan found in TAP output/, "no parse error: No plan found");

# write out for investigation
if (open my $F, ">", "/tmp/ATH_STM.html") { print $F $html; close $F; }

# ============================================================

done_testing();
