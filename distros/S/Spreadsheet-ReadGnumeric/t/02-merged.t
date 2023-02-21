#!/usr/bin/perl
#
# [variation on t/617_merged.t from Spreadsheet::Read, as is the original Excel
# spreadsheet from which t/data/merged.gnumeric is derived; thanks to H.Merijn
# Brand for doing half my testing job!  -- rgr, 9-Feb-23.]
#

use strict;
use warnings;

use Test::More tests => 20;

use Spreadsheet::ReadGnumeric;

my $parser = Spreadsheet::ReadGnumeric->new(attr => 1);

ok (my $ss = $parser->parse("t/data/merged.gnumeric")->[1],
    "Read merged.gnumeric with attributes")
    or die;

is_deeply ($ss->{merged}, [[1,2,1,3],[2,1,3,2]], "Merged areas");

ok (! $ss->{attr}[1][1], "unmerged A1");
is ($ss->{attr}[2][1]{merged}, 1, "merged B1");
is ($ss->{attr}[3][1]{merged}, 1, "merged C1");
is ($ss->{attr}[1][2]{merged}, 1, "merged A2");
is ($ss->{attr}[2][2]{merged}, 1, "merged B2");
is ($ss->{attr}[3][2]{merged}, 1, "merged C2");
is ($ss->{attr}[1][3]{merged}, 1, "merged A3");
ok (! $ss->{attr}[2][3]{merged}, "unmerged B3");
ok (! $ss->{attr}[3][3]{merged}, "unmerged C3");

$parser = Spreadsheet::ReadGnumeric->new(attr => 1, merge => 1);
ok ($ss = $parser->parse("t/data/merged.gnumeric")->[1],
    "Read merged.gnumeric with 'merge => 1'");

is ($ss->{attr}[2][1]{merged}, "B1", "merged B1");
is ($ss->{attr}[3][1]{merged}, "B1", "merged C1");
is ($ss->{attr}[1][2]{merged}, "A2", "merged A2");
is ($ss->{attr}[2][2]{merged}, "B1", "merged B2");
is ($ss->{attr}[3][2]{merged}, "B1", "merged C2");
is ($ss->{attr}[1][3]{merged}, "A2", "merged A3");
ok (! $ss->{attr}[2][3]{merged}, "unmerged B3");
ok (! $ss->{attr}[3][3]{merged}, "unmerged C3");
