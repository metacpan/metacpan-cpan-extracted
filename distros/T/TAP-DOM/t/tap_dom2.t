#! /usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 14;

use TAP::DOM;
use Data::Dumper;

my $tap;
{
        local $/;
        open (TAP, "< t/some_tap2.txt") or die "Cannot read t/some_tap2.txt";
        $tap = <TAP>;
        close TAP;
}

my $tapdata = TAP::DOM->new( tap => $tap );
#my $tapdata = tapdata( tap => $tap );
# print Dumper($tapdata);

is($tapdata->{tests_run},      1, "tests_run");
is($tapdata->{tests_planned},  1, "tests_planned");
is($tapdata->{version},       13, "version");
is($tapdata->{plan},      "1..1", "plan");

is($tapdata->{lines}[2]{number},  1,     "[2] number");
is($tapdata->{lines}[2]{is_test}, 1,     "[2] is_test");
is($tapdata->{lines}[2]{is_ok},   1,     "[2] is_ok");

#diag Dumper($tapdata->{lines});
is($tapdata->{lines}[2]{_children}[0]{data}{LOC}{CPU0}, "1136220",     "[2]...{data}");

is($tapdata->{summary}{todo},         0,      "summary todo");
is($tapdata->{summary}{total},        1,      "summary total");
is($tapdata->{summary}{passed},       1,      "summary passed");
is($tapdata->{summary}{status},       "PASS", "summary status");
is($tapdata->{summary}{all_passed},   1,      "summary all_passed");
is($tapdata->{summary}{has_problems}, 0,      "summary has_problems");
