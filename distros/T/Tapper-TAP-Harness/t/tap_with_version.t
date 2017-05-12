#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Tapper::TAP::Harness;
use File::Slurp 'slurp';
use Data::Dumper;

my $tap = slurp ("t/tap_archive_kvm_migration.tap");

# ============================================================

plan tests => 9;

my $harness = new Tapper::TAP::Harness( tap => $tap );

$harness->evaluate_report();

is(scalar @{$harness->parsed_report->{tap_sections}}, 1, "count sections");
#print STDERR Dumper( \(map {$_->{raw} } @{$harness->parsed_report->{tap_sections}}) );

my $first_section = $harness->parsed_report->{tap_sections}->[0];

# use Data::Dumper;
# diag(Dumper($first_section));

is($harness->parsed_report->{report_meta}{'suite-name'},    'KVM-Migration-Checkpoint', "report meta suite name");
is($harness->parsed_report->{report_meta}{'suite-version'}, '0.01',                     "report meta suite version");
is($harness->parsed_report->{report_meta}{'starttime-test-program'}, 'Fri, 08 Aug 2008 14:34:48 +0200', "report meta starttime test program");
is($harness->parsed_report->{report_meta}{'endtime-test-program'},   'Fri, 08 Aug 2008 14:36:21 +0200', "report meta endttime test program");
like($harness->parsed_report->{report_meta}{'reportgroup-arbitrary'}, qr/kvm-/, "report meta reportgroup arbitrary");

is($first_section->{section_name},'section-000', "first section name");

is($first_section->{section_meta}{'suite-name'},             'KVM-Migration-Checkpoint',                                           "report meta suite name");
is($first_section->{section_meta}{'suite-version'},          '0.01',                                                               "report meta suite version");

