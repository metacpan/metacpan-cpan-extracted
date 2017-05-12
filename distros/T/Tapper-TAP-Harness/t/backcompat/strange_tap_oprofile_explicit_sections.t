#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Tapper::TAP::Harness;
use File::Slurp 'slurp';
use Data::Dumper;
use Test::Deep;

plan tests => 10;

my $tap;
my $harness;
my $interrupts_before_section;

# ============================================================

$tap     = slurp ("t/backcompat/tap_archive_oprofile_explicit_sections.tap");
$harness = new Tapper::TAP::Harness( tap => $tap );
$harness->evaluate_report();

#print STDERR Dumper($harness->parsed_report->{tap_sections});
# foreach (map { $_->{section_name} }  @{$harness->parsed_report->{tap_sections}})
# {
#         diag "Section: $_";
# }

is( scalar @{$harness->parsed_report->{tap_sections}}, 4, "oprofile section count");
cmp_bag ([ map { $_->{section_name} } @{$harness->parsed_report->{tap_sections}}],
         [
          qw/
                    metainfo
                    kerneltype
                    uptime
                    misc
            /
         ],
         "tap sections");

my $metainfo = $harness->parsed_report->{tap_sections}->[3];
is ($metainfo->{section_name}, 'misc', "oprofile section name misc");

like ($harness->parsed_report->{tap_sections}->[2]->{raw}, qr/uptime: 0:00/, "uptime raw contains YAML");
like ($harness->parsed_report->{tap_sections}->[3]->{raw}, qr/misc bar/, "misc raw contains tests");

# ============================================================

$tap     = slurp ("t/backcompat/tap_archive_oprofile_reallive.tap");
$harness = new Tapper::TAP::Harness( tap => $tap );
$harness->evaluate_report();

my $html = $harness->generate_html();
if (open my $F, ">", "/tmp/ATH_oprofile.html") {
        print $F $html;
        close $F;
}

#print STDERR Dumper($harness->parsed_report->{tap_sections});
# foreach (map { $_->{section_name} }  @{$harness->parsed_report->{tap_sections}})
# {
#         diag "Section: $_";
# }

is( scalar @{$harness->parsed_report->{tap_sections}}, 9, "oprofile section count");
#                    version.tap
#                    reportgroup.tap
cmp_bag ([ map { $_->{section_name} } @{$harness->parsed_report->{tap_sections}}],
         [
          qw/
                    metainfo
                    kerneltype
                    uptime
                    kernel-todo
                    kernel-kernel
                    clean-todo
                    clean-clean
                    oprofile-todo
                    oprofile-oprofile
            /
         ],
         "tap sections");

$metainfo = $harness->parsed_report->{tap_sections}->[3];
is ($metainfo->{section_name}, 'kernel-todo', "oprofile section name misc");

like ($harness->parsed_report->{tap_sections}->[2]->{raw}, qr/uptime: 0:00/, "uptime raw contains YAML");
like ($harness->parsed_report->{tap_sections}->[4]->{raw}, qr/update AMD Northbridge events access control policy/ms, "kernel-todo raw contains expected text");
