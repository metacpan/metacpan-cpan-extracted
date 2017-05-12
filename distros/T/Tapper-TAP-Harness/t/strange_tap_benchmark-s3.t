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

$tap     = slurp ("t/tap_archive_benchmark-s3.tap");
$harness = new Tapper::TAP::Harness( tap => $tap );
$harness->evaluate_report();

# print STDERR Dumper($harness->parsed_report->{tap_sections});
# foreach (map { $_->{section_name} }  @{$harness->parsed_report->{tap_sections}})
# {
#         diag "Section: $_";
# }

is( scalar @{$harness->parsed_report->{tap_sections}}, 1, "section count");
cmp_deeply ([ map { $_->{section_name} } @{$harness->parsed_report->{tap_sections}}],
            [ qw/ results / ],
         "tap sections");

my $results = $harness->parsed_report->{tap_sections}->[0];
is ($results->{section_name}, 'results', "section name results");

done_testing;
