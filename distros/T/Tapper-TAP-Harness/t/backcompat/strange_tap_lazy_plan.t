#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Tapper::TAP::Harness;
use File::Slurp 'slurp';
use Data::Dumper;

my $tap = slurp ("t/backcompat/tap_archive_tapper_lazy_plan.tap");

# ============================================================

plan tests => 30;

my $harness = new Tapper::TAP::Harness( tap => $tap );

$harness->evaluate_report();

is(scalar @{$harness->parsed_report->{tap_sections}}, 10, "count sections");
#print STDERR Dumper( \(map {$_->{raw} } @{$harness->parsed_report->{tap_sections}}) );

my $first_section = $harness->parsed_report->{tap_sections}->[0];

# use Data::Dumper;
# diag(Dumper($first_section));

is($harness->parsed_report->{report_meta}{'suite-name'},    'Artemis',       "report meta suite name");
is($harness->parsed_report->{report_meta}{'suite-version'}, '2.010004',      "report meta suite version");
is($harness->parsed_report->{report_meta}{'suite-type'},    'software',      "report meta suite type");
is($harness->parsed_report->{report_meta}{'machine-name'},  'bascha',        "report meta machine name");
is($harness->parsed_report->{report_meta}{'starttime-test-program'}, 'Fri Jun 13 11:16:35 CEST 2008', "report meta starttime test program");
is($harness->parsed_report->{report_meta}{'reportgroup-arbitrary'}, '29365', "report meta reportgroup arbitrary");
is($harness->parsed_report->{report_meta}{'reportgroup-testrun'}, '478',     "report meta reportgroup testrun");

is($first_section->{section_name},'t/00-artemis-meta.t', "first section name");

is($first_section->{section_meta}{'suite-name'},             'Artemis',                                                            "report meta suite name");
is($first_section->{section_meta}{'suite-version'},          '2.010004',                                                           "report meta suite version");
is($first_section->{section_meta}{'suite-type'},             'software',                                                            "report meta suite type");
is($first_section->{section_meta}{'language-description'},   'Perl 5.010000, /2home/ss5/perl510/bin/perl',                         "report meta language description");
is($first_section->{section_meta}{'uname'}, 'Linux bascha 2.6.24-18-generic #1 SMP Wed May 28 19:28:38 UTC 2008 x86_64 GNU/Linux', "report meta uname");
is($first_section->{section_meta}{'osname'},                 'Ubuntu 8.04',                                                        "report meta osname");
is($first_section->{section_meta}{'cpuinfo'},                '2 cores [AMD Athlon(tm) 64 X2 Dual Core Processor 6000+]',           "report meta cpuinfo");
is($first_section->{section_meta}{'ram'},                    '1887MB',                                                             "report meta ram");

is($first_section->{db_section_meta}{'language_description'},   'Perl 5.010000, /2home/ss5/perl510/bin/perl',                                          "db meta language description");
is($first_section->{db_section_meta}{'uname'},                  'Linux bascha 2.6.24-18-generic #1 SMP Wed May 28 19:28:38 UTC 2008 x86_64 GNU/Linux', "db meta uname");
is($first_section->{db_section_meta}{'osname'},                 'Ubuntu 8.04',                                                                         "db meta osname");
is($first_section->{db_section_meta}{'cpuinfo'},                '2 cores [AMD Athlon(tm) 64 X2 Dual Core Processor 6000+]',                            "db meta cpuinfo");
is($first_section->{db_section_meta}{'ram'},                    '1887MB',                                                                              "db meta ram");

$harness = new Tapper::TAP::Harness( tap => $tap );
$harness->evaluate_report();
is(scalar @{$harness->parsed_report->{tap_sections}}, 10, "count sections"); # check to trigger preparation errors

# my $html = $harness->generate_html;
# open (XYZ, ">", "xyz.html") or die "Cannot write xyz.html";
# print XYZ $html;
# close XYZ;

like($harness->_get_prove, qr|/.*bin.*/prove|, 'looks like prove command');

# ============================================================

$harness = new Tapper::TAP::Harness;
$harness->section_names({
                         affe   => 1,
                         affe0  => 1,
                         affe1  => 1,
                         # affe2

                         loewe  => 1,
                         # loewe0

                         tiger  => 1,
                         # tiger0
                         tiger1 => 1,
                         tiger2 => 1,

                         zomtec  => 1,
                         zomtec0 => 1,
                         # zomtec1
                         zomtec2 => 1,
                        });

is ($harness->_unique_section_name("affe"),   "affe2",   "unique section name affe2");
is ($harness->_unique_section_name("loewe"),  "loewe1",  "unique section name loewe1");
is ($harness->_unique_section_name("tiger"),  "tiger3",  "unique section name tiger3");
is ($harness->_unique_section_name("zomtec"), "zomtec1", "unique section name zomtec1");
is ($harness->_unique_section_name("foo"),    "foo",     "unique section name foo");
is ($harness->_unique_section_name("foo"),    "foo1",    "unique section name foo1");

# # ============================================================

# $tap     = slurp ("t/backcompat/tap_archive_kernbench_lazy_plan.tap");
# $harness = new Tapper::TAP::Harness( tap => $tap );
# $harness->evaluate_report();
# my $interrupts_before_section = $harness->parsed_report->{tap_sections}->[1];
# is ($interrupts_before_section->{section_name}, 'stats-proc-interrupts-before', "lazyplan section name interrupts-before ");

