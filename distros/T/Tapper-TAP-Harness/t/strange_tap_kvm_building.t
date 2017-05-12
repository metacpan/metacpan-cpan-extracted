#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Tapper::TAP::Harness;
use File::Slurp 'slurp';
use Data::Dumper;

my $tap = slurp ("t/tap_archive_kvm_building.tap");

# ============================================================

my $harness = new Tapper::TAP::Harness( tap => $tap );

$harness->evaluate_report();

is(scalar @{$harness->parsed_report->{tap_sections}}, 3, "count sections");
#print STDERR Dumper( \(map {$_->{raw} } @{$harness->parsed_report->{tap_sections}}) );

my $first_section = $harness->parsed_report->{tap_sections}->[0];

# use Data::Dumper;
# diag(Dumper($first_section));

is($harness->parsed_report->{report_meta}{'suite-name'},    'tbd', "report meta suite name");
is($harness->parsed_report->{report_meta}{'suite-version'}, '0.01', "report meta suite version");

my $sections = $harness->parsed_report->{tap_sections};
is($sections->[0]->{section_name},'tapper-meta-information', "tapper-meta-information");
is($sections->[1]->{section_meta}{'description'},   'some rpm-userspace', "section description userspace");
is($sections->[2]->{section_meta}{'description'},   'some rpm-kernel',    "section description kernel");

done_testing();
