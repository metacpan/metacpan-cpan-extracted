#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use TAP::DOM ':constants';
use Data::Dumper;

my $l;
my $severity;

# ============================== typical report ==============================

my $tap;
{
        local $/;
        open (TAP, "< t/some_tap7_taplevel.txt") or die "Cannot read t/some_tap7_taplevel.txt";
        $tap = <TAP>;
        close TAP;
}

my $tapdata = TAP::DOM->new( tap => $tap );
# diag Dumper($tapdata);

is($tapdata->{tests_run},      6, "tests_run");
is($tapdata->{tests_planned},  6, "tests_planned");
is($tapdata->{version},       13, "version");
is($tapdata->{plan},      "1..6", "plan");

# TAP severity levels:
#  - 0 ... missing        # eg. on non-is_test lines
#  - 1 ... ok
#  - 2 ... ok_todo
#  - 3 ... ok_skip
#  - 4 ... notok_todo
#  - 5 ... notok
#  - 6 ... notok_skip     # very last as it's a forbidden state and therefore worse than normal notok

# TAP severity level definition:
#
# |--------+-------+----------+--------------+----------+------------+----------|
# | *type* | is_ok | has_todo | is_actual_ok | has_skip | *mnemonic* | *tapcon* |
# |--------+-------+----------+--------------+----------+------------+----------|
# | plan   | undef |    undef |        undef |        1 | ok_skip    |        3 |
# |--------+-------+----------+--------------+----------+------------+----------|
# | test   |     1 |        0 |            0 |        0 | ok         |        1 |
# | test   |     1 |        1 |            1 |        0 | ok_todo    |        2 |
# | test   |     1 |        0 |            0 |        1 | ok_skip    |        3 |
# | test   |     1 |        1 |            0 |        0 | notok_todo |        4 |
# | test   |     0 |        0 |            0 |        0 | notok      |        5 |
# | test   |     0 |        0 |            0 |        1 | notok_skip |        6 |
# |--------+-------+----------+--------------+----------+------------+----------|
# |        |       |          |              |          | missing    |        0 |
# |--------+-------+----------+--------------+----------+------------+----------|

# severity 0 - missing - TAP version
$l = 0; $severity=0;
is($tapdata->{lines}[$l]{type},         'version',                "[$severity] type");
is($tapdata->{lines}[$l]{number},       undef,                    "[$severity] number");
is($tapdata->{lines}[$l]{description},  undef,                    "[$severity] description");
is($tapdata->{lines}[$l]{explanation},  undef,                    "[$severity] explanation");
is($tapdata->{lines}[$l]{is_test},      0,                        "[$severity] is_test");
is($tapdata->{lines}[$l]{is_ok},        undef,                    "[$severity] is_ok");
is($tapdata->{lines}[$l]{has_todo},     0,                        "[$severity] has_todo");
is($tapdata->{lines}[$l]{is_actual_ok}, 0,                        "[$severity] is_actual_ok");
is($tapdata->{lines}[$l]{has_skip},     0,                        "[$severity] has_skip");
is($tapdata->{lines}[$l]{severity},     $severity,                "[$severity] severity");
is($tapdata->{lines}[$l]->severity,     $severity,                "[$severity] severity accessor");

# severity 0 - missing - Plan
$l = 1; $severity=0;
is($tapdata->{lines}[$l]{type},         'plan',                   "[$severity] type");
is($tapdata->{lines}[$l]{number},       undef,                    "[$severity] number");
is($tapdata->{lines}[$l]{description},  undef,                    "[$severity] description");
is($tapdata->{lines}[$l]{explanation},  '',                       "[$severity] explanation");
is($tapdata->{lines}[$l]{is_test},      0,                        "[$severity] is_test");
is($tapdata->{lines}[$l]{is_ok},        undef,                    "[$severity] is_ok");
is($tapdata->{lines}[$l]{has_todo},     0,                        "[$severity] has_todo");
is($tapdata->{lines}[$l]{is_actual_ok}, 0,                        "[$severity] is_actual_ok");
is($tapdata->{lines}[$l]{has_skip},     0,                        "[$severity] has_skip");
is($tapdata->{lines}[$l]{severity},     $severity,                "[$severity] severity");
is($tapdata->{lines}[$l]->severity,     $severity,                "[$severity] severity accessor");

# severity 1 - ok
$l = 2; $severity=1;
is($tapdata->{lines}[$l]{type},         'test',                   "[$severity] type");
is($tapdata->{lines}[$l]{number},       1,                        "[$severity] number");
is($tapdata->{lines}[$l]{description},  "level 1 ok",             "[$severity] description");
is($tapdata->{lines}[$l]{explanation},  "",                       "[$severity] explanation");
is($tapdata->{lines}[$l]{is_test},      1,                        "[$severity] is_test");
is($tapdata->{lines}[$l]{is_ok},        1,                        "[$severity] is_ok");
is($tapdata->{lines}[$l]{has_todo},     0,                        "[$severity] has_todo");
is($tapdata->{lines}[$l]{is_actual_ok}, 0,                        "[$severity] is_actual_ok");
is($tapdata->{lines}[$l]{has_skip},     0,                        "[$severity] has_skip");
is($tapdata->{lines}[$l]{severity},     $severity,                "[$severity] severity");
is($tapdata->{lines}[$l]->severity,     $severity,                "[$severity] severity accessor");

# severity 2 - ok_todo
$l = 3; $severity=2;
is($tapdata->{lines}[$l]{type},         'test',                   "[$severity] type");
is($tapdata->{lines}[$l]{number},       2,                        "[$severity] number");
is($tapdata->{lines}[$l]{description},  "level 2 ok_todo",        "[$severity] description");
is($tapdata->{lines}[$l]{explanation},  "ok_todo_explanation",    "[$severity] explanation");
is($tapdata->{lines}[$l]{is_test},      1,                        "[$severity] is_test");
is($tapdata->{lines}[$l]{is_ok},        1,                        "[$severity] is_ok");
is($tapdata->{lines}[$l]{has_todo},     1,                        "[$severity] has_todo");
is($tapdata->{lines}[$l]{is_actual_ok}, 1,                        "[$severity] is_actual_ok");
is($tapdata->{lines}[$l]{has_skip},     0,                        "[$severity] has_skip");
is($tapdata->{lines}[$l]{severity},     $severity,                "[$severity] severity");
is($tapdata->{lines}[$l]->severity,     $severity,                "[$severity] severity accessor");

# severity 3 - ok_skip
$l = 4; $severity=3;
is($tapdata->{lines}[$l]{type},         'test',                   "[$severity] type");
is($tapdata->{lines}[$l]{number},       3,                        "[$severity] number");
is($tapdata->{lines}[$l]{description},  "level 3 ok_skip",        "[$severity] description");
is($tapdata->{lines}[$l]{explanation},  "ok_skip_explanation",    "[$severity] explanation");
is($tapdata->{lines}[$l]{is_test},      1,                        "[$severity] is_test");
is($tapdata->{lines}[$l]{is_ok},        1,                        "[$severity] is_ok");
is($tapdata->{lines}[$l]{has_todo},     0,                        "[$severity] has_todo");
is($tapdata->{lines}[$l]{is_actual_ok}, 0,                        "[$severity] is_actual_ok");
is($tapdata->{lines}[$l]{has_skip},     1,                        "[$severity] has_skip");
is($tapdata->{lines}[$l]{severity},     $severity,                "[$severity] severity");
is($tapdata->{lines}[$l]->severity,     $severity,                "[$severity] severity accessor");

# severity 4 - notok_todo
$l = 5; $severity=4;
is($tapdata->{lines}[$l]{type},         'test',                   "[$severity] type");
is($tapdata->{lines}[$l]{number},       4,                        "[$severity] number");
is($tapdata->{lines}[$l]{description},  "level 4 notok_todo",     "[$severity] description");
is($tapdata->{lines}[$l]{explanation},  "notok_todo_explanation", "[$severity] explanation");
is($tapdata->{lines}[$l]{is_test},      1,                        "[$severity] is_test");
is($tapdata->{lines}[$l]{is_ok},        1,                        "[$severity] is_ok");
is($tapdata->{lines}[$l]{has_todo},     1,                        "[$severity] has_todo");
is($tapdata->{lines}[$l]{is_actual_ok}, 0,                        "[$severity] is_actual_ok");
is($tapdata->{lines}[$l]{has_skip},     0,                        "[$severity] has_skip");
is($tapdata->{lines}[$l]{severity},     $severity,                "[$severity] severity");
is($tapdata->{lines}[$l]->severity,     $severity,                "[$severity] severity accessor");

# severity 5 - notok
$l = 6; $severity=5;
is($tapdata->{lines}[$l]{type},         'test',                   "[$severity] type");
is($tapdata->{lines}[$l]{number},       5,                        "[$severity] number");
is($tapdata->{lines}[$l]{description},  "level 5 notok",          "[$severity] description");
is($tapdata->{lines}[$l]{explanation},  "",                       "[$severity] explanation");
is($tapdata->{lines}[$l]{is_test},      1,                        "[$severity] is_test");
is($tapdata->{lines}[$l]{is_ok},        0,                        "[$severity] is_ok");
is($tapdata->{lines}[$l]{has_todo},     0,                        "[$severity] has_todo");
is($tapdata->{lines}[$l]{is_actual_ok}, 0,                        "[$severity] is_actual_ok");
is($tapdata->{lines}[$l]{has_skip},     0,                        "[$severity] has_skip");
is($tapdata->{lines}[$l]{severity},     $severity,                "[$severity] severity");
is($tapdata->{lines}[$l]->severity,     $severity,                "[$severity] severity accessor");

# severity 6 - notok_skip
$l = 7; $severity=6;
is($tapdata->{lines}[$l]{type},         'test',                   "[$severity] type");
is($tapdata->{lines}[$l]{number},       6,                        "[$severity] number");
is($tapdata->{lines}[$l]{description},  "level 6 notok_skip",     "[$severity] description");
is($tapdata->{lines}[$l]{explanation},  "notok_skip_explanation", "[$severity] explanation");
is($tapdata->{lines}[$l]{is_test},      1,                        "[$severity] is_test");
is($tapdata->{lines}[$l]{is_ok},        0,                        "[$severity] is_ok");
is($tapdata->{lines}[$l]{has_todo},     0,                        "[$severity] has_todo");
is($tapdata->{lines}[$l]{is_actual_ok}, 0,                        "[$severity] is_actual_ok");
is($tapdata->{lines}[$l]{has_skip},     1,                        "[$severity] has_skip");
is($tapdata->{lines}[$l]{severity},     $severity,                "[$severity] severity");
is($tapdata->{lines}[$l]->severity,     $severity,                "[$severity] severity accessor");

# severity 0 - Pragma
$l = 8; $severity=0;
is($tapdata->{lines}[$l]{type},         'pragma',                 "[$severity] type");
is($tapdata->{lines}[$l]{number},       undef,                    "[$severity] number");
is($tapdata->{lines}[$l]{description},  undef,                    "[$severity] description");
is($tapdata->{lines}[$l]{explanation},  undef,                    "[$severity] explanation");
is($tapdata->{lines}[$l]{is_test},      0,                        "[$severity] is_test");
is($tapdata->{lines}[$l]{is_ok},        undef,                    "[$severity] is_ok");
is($tapdata->{lines}[$l]{has_todo},     0,                        "[$severity] has_todo");
is($tapdata->{lines}[$l]{is_actual_ok}, 0,                        "[$severity] is_actual_ok");
is($tapdata->{lines}[$l]{has_skip},     0,                        "[$severity] has_skip");
is($tapdata->{lines}[$l]{severity},     $severity,                "[$severity] severity");
is($tapdata->{lines}[$l]->severity,     $severity,                "[$severity] severity accessor");

# ============================== skip_all report ==============================

my $tap_skipall;
{
  local $/;
  open (TAP, "< t/some_tap7_taplevel_skipall.txt") or die "Cannot read t/some_tap7_taplevel_skipall.txt";
  $tap_skipall = <TAP>;
  close TAP;
}
my $tapdata_skipall = TAP::DOM->new( tap => $tap_skipall );

is($tapdata_skipall->{tests_run},      0, "tests_run");
is($tapdata_skipall->{tests_planned},  0, "tests_planned");
is($tapdata_skipall->{version},       13, "version");
is($tapdata_skipall->{plan}, "1..0 # SKIP ok_skipall_reason", "plan");

# severity 0 - missing - TAP version
$l = 0; $severity=0;
is($tapdata_skipall->{lines}[$l]{number},       undef,                    "[$severity] number");
is($tapdata_skipall->{lines}[$l]{description},  undef,                    "[$severity] description");
is($tapdata_skipall->{lines}[$l]{explanation},  undef,                    "[$severity] explanation");
is($tapdata_skipall->{lines}[$l]{is_test},      0,                        "[$severity] is_test");
is($tapdata_skipall->{lines}[$l]{is_ok},        undef,                    "[$severity] is_ok");
is($tapdata_skipall->{lines}[$l]{has_todo},     0,                        "[$severity] has_todo");
is($tapdata_skipall->{lines}[$l]{is_actual_ok}, 0,                        "[$severity] is_actual_ok");
is($tapdata_skipall->{lines}[$l]{has_skip},     0,                        "[$severity] has_skip");
is($tapdata_skipall->{lines}[$l]{severity},     $severity,                "[$severity] severity");
is($tapdata_skipall->{lines}[$l]->severity,     $severity,                "[$severity] severity accessor");

# severity 0 - missing - Plan
$l = 1; $severity=3;
is($tapdata_skipall->{lines}[$l]{number},       undef,                    "[$severity] number");
is($tapdata_skipall->{lines}[$l]{description},  undef,                    "[$severity] description");
is($tapdata_skipall->{lines}[$l]{explanation},  "ok_skipall_reason",      "[$severity] explanation");
is($tapdata_skipall->{lines}[$l]{is_test},      0,                        "[$severity] is_test");
is($tapdata_skipall->{lines}[$l]{is_ok},        undef,                    "[$severity] is_ok");
is($tapdata_skipall->{lines}[$l]{has_todo},     0,                        "[$severity] has_todo");
is($tapdata_skipall->{lines}[$l]{is_actual_ok}, 0,                        "[$severity] is_actual_ok");
is($tapdata_skipall->{lines}[$l]{has_skip},     1,                        "[$severity] has_skip");
is($tapdata_skipall->{lines}[$l]{severity},     $severity,                "[$severity] severity");
is($tapdata_skipall->{lines}[$l]->severity,     $severity,                "[$severity] severity accessor");

#diag Dumper($tapdata);

done_testing();
