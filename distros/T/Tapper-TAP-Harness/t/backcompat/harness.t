#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Tapper::TAP::Harness;
use File::Slurp 'slurp';
use Data::Dumper;
use TAP::DOM;

my $tap = slurp ("t/backcompat/tap_archive_tapper.tap");

# ============================================================

my $harness = Tapper::TAP::Harness->new( tap => $tap );

$harness->evaluate_report();
#diag(Dumper($harness->parsed_report->{tap_sections}));

is(scalar @{$harness->parsed_report->{tap_sections}}, 10, "count sections");

my $first_section = $harness->parsed_report->{tap_sections}->[0];

# ============================================================

#diag Dumper();
my $dom = TAP::DOM->new( tap => "TAP Version 13\n".$harness->parsed_report->{tap_sections}->[3]->{raw} );
#diag(Dumper($dom));
is($dom->{tests_run}, 1, "section 3 tests run");
ok($dom->{is_good_plan}, "section 3 good plan");

# ============================================================

my $similar_tap = slurp ("t/backcompat/tap_archive_tapper_prove3.15.tap");
my $harness2 = Tapper::TAP::Harness->new( tap => $similar_tap );
$harness2->evaluate_report();
#diag(Dumper($harness2->parsed_report->{tap_sections}));

my $dom2 = TAP::DOM->new( tap => "TAP Version 13\n".$harness2->parsed_report->{tap_sections}->[3]->{raw} );
#diag(Dumper($dom2));
is($dom2->{tests_run}, 1, "section 3a tests run");
ok($dom2->{is_good_plan}, "section 3a good plan");

# ============================================================

$similar_tap = slurp ("t/backcompat/tap_archive_tapper_reports_dpath_prove3.15.tap");
my $harness3 = Tapper::TAP::Harness->new( tap => $similar_tap );
$harness3->evaluate_report();
#print STDERR Dumper($harness3->parsed_report->{tap_sections});

my $raw  = $harness3->parsed_report->{tap_sections}->[2]->{raw};
my $dom3 = TAP::DOM->new( tap => "TAP Version 13\n".$raw );
#diag(Dumper($dom3));
is(scalar @{$harness3->parsed_report->{tap_sections}}, 8, "section 3b count sections");

is($dom3->{tests_run}, 29, "section 3b tests run");
ok($dom3->{is_good_plan}, "section 3b good plan");

# ============================================================

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
is($first_section->{section_meta}{'ticket-url'},             'https://affe.tiger.com/bugs/show_bug.cgi?id=901',                    "report meta ticket url");
is($first_section->{section_meta}{'wiki-url'},               'https://affe.tiger.com/wiki/Artemis/autoreport',                     "report meta wiki url");
is($first_section->{section_meta}{'planning-id'},            'foo.bar.artemis.autoreport',                                         "report meta planning id");
is($first_section->{section_meta}{'tags'},                   'sles10sp2 novell bz901',                                             "report meta tags");

is($first_section->{db_section_meta}{'language_description'},   'Perl 5.010000, /2home/ss5/perl510/bin/perl',                                          "db meta language description");
is($first_section->{db_section_meta}{'uname'},                  'Linux bascha 2.6.24-18-generic #1 SMP Wed May 28 19:28:38 UTC 2008 x86_64 GNU/Linux', "db meta uname");
is($first_section->{db_section_meta}{'osname'},                 'Ubuntu 8.04',                                                                         "db meta osname");
is($first_section->{db_section_meta}{'cpuinfo'},                '2 cores [AMD Athlon(tm) 64 X2 Dual Core Processor 6000+]',                            "db meta cpuinfo");
is($first_section->{db_section_meta}{'ram'},                    '1887MB',                                                                              "db meta ram");
is($first_section->{db_section_meta}{'ticket_url'},             'https://affe.tiger.com/bugs/show_bug.cgi?id=901',                                     "db meta ticket url");
is($first_section->{db_section_meta}{'wiki_url'},               'https://affe.tiger.com/wiki/Artemis/autoreport',                                      "db meta wiki url");
is($first_section->{db_section_meta}{'planning_id'},            'foo.bar.artemis.autoreport',                                                          "db meta planning id");
is($first_section->{db_section_meta}{'tags'},                   'sles10sp2 novell bz901',                                                              "db meta tags");

$harness = Tapper::TAP::Harness->new( tap => $tap );
my $html = $harness->generate_html;
is(scalar @{$harness->parsed_report->{tap_sections}}, 10, "count sections"); # check to trigger preparation errors

like($harness->_get_prove, qr|/.*bin.*/prove|, 'looks like prove command');

# ============================================================

$harness = Tapper::TAP::Harness->new;
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

done_testing;
