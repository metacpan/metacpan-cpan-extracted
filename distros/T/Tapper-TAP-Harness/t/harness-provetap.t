#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Tapper::TAP::Harness;
use File::Slurp 'slurp';
use Data::Dumper;
use TAP::DOM;

my $similar_tap = slurp ("t/tap_archive_tapper_reports_dpath_prove3.15.tap");
my $harness3 = Tapper::TAP::Harness->new( tap => $similar_tap );
$harness3->evaluate_report();
# diag Dumper($harness3->parsed_report->{tap_sections});

my $raw  = $harness3->parsed_report->{tap_sections}->[2]->{raw};
my $dom3 = TAP::DOM->new( tap => "TAP Version 13\n".$raw );
#diag(Dumper($dom3));
is(scalar @{$harness3->parsed_report->{tap_sections}}, 8, "section 3b count sections");

is($dom3->{tests_run}, 30, "section 3b tests run");
ok($dom3->{is_good_plan}, "section 3b good plan");

done_testing;
