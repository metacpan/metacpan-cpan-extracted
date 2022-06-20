#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Tapper::TAP::Harness;
use File::Slurp 'slurp';
use Data::Dumper;
use TAP::DOM;

my $tap = slurp ("t/tap-archive-3-with-empty.tgz");

# ============================================================

my $harness = Tapper::TAP::Harness->new( tap => $tap, tap_is_archive => 1 );

$harness->evaluate_report();
#diag(Dumper($harness->parsed_report->{tap_sections}));

is(scalar @{$harness->parsed_report->{tap_sections}}, 5, "count sections");

my $first_section = $harness->parsed_report->{tap_sections}->[0];
my $last_section = $harness->parsed_report->{tap_sections}->[-1];

# ============================================================

#diag Dumper();
my $dom = TAP::DOM->new( tap => "TAP Version 13\n".$harness->parsed_report->{tap_sections}->[3]->{raw} );
#diag(Dumper($dom));
is($dom->{tests_run}, 3, "section 3 tests run");
ok($dom->{is_good_plan}, "section 3 good plan");

# ============================================================

is($harness->parsed_report->{report_meta}{'suite-name'},    'Tapper-Test',       "report meta suite name");
is($harness->parsed_report->{report_meta}{'suite-version'}, '2.010012',           "report meta suite version");
is($harness->parsed_report->{report_meta}{'suite-type'},    'software',           "report meta suite type");
is($harness->parsed_report->{report_meta}{'machine-name'},  'ss5-netbook',        "report meta machine name");
is($harness->parsed_report->{report_meta}{'starttime-test-program'}, 'Thu, 28 Oct 2010 16:13:27 +0200', "report meta starttime test program");

is($first_section->{section_name},'t/00-tapper-meta.t', "first section name");

is($first_section->{section_meta}{'suite-name'},             'Tapper-Test',                                                            "report meta suite name");
is($first_section->{section_meta}{'suite-version'},          '2.010012',                                                           "report meta suite version");
is($first_section->{section_meta}{'suite-type'},             'software',                                                           "report meta suite type");
is($first_section->{section_meta}{'language-description'},   'Perl 5.012001, /home/ss5/perl5/perlbrew/perls/perl-5.12.1/bin/perl', "report meta language description");
is($first_section->{section_meta}{'uname'}, 'Linux ss5-netbook 2.6.31-21-generic #59-Ubuntu SMP Wed Mar 24 07:28:56 UTC 2010 i686 GNU/Linux', "report meta uname");
is($first_section->{section_meta}{'osname'},                 'Ubuntu 10.10',                                                       "report meta osname");
is($first_section->{section_meta}{'cpuinfo'},                '2 cores [Intel(R) Atom(TM) CPU N270   @ 1.60GHz]',                   "report meta cpuinfo");
is($first_section->{section_meta}{'ram'},                    '993MB',                                                              "report meta ram");

is($first_section->{db_section_meta}{'language_description'},   'Perl 5.012001, /home/ss5/perl5/perlbrew/perls/perl-5.12.1/bin/perl', "db meta language description");
is($first_section->{db_section_meta}{'uname'},                  'Linux ss5-netbook 2.6.31-21-generic #59-Ubuntu SMP Wed Mar 24 07:28:56 UTC 2010 i686 GNU/Linux', "db meta uname");
is($first_section->{db_section_meta}{'osname'},                 'Ubuntu 10.10',                                                       "db meta osname");
is($first_section->{db_section_meta}{'cpuinfo'},                '2 cores [Intel(R) Atom(TM) CPU N270   @ 1.60GHz]',                   "db meta cpuinfo");
is($first_section->{db_section_meta}{'ram'},                    '993MB',                                                              "db meta ram");


# ============================================================

# empty tap

is($last_section->{section_name},'t/zero_size.t', "last section name");

my @expected_lines = split("\n", $TAP::DOM::noempty_tap);
my $i = 1;
for my $el (@expected_lines) {
  # There might be more auto-generated lines in it, like "TAP version # 13"
  # for which we don't check.
  like($last_section->{raw}, qr/\Q$el\E/,  "last section expected replacement line ".$i++);
  diag "expected line: $el";
}

done_testing;
