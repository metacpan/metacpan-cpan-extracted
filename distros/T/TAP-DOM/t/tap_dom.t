#! /usr/bin/env perl

use strict;
use warnings;

use Test::More 0.88;

use TAP::DOM;
use Data::Dumper;

my $tap;
{
        local $/;
        open (TAP, "< t/some_tap.txt") or die "Cannot read t/some_tap.txt";
        $tap = <TAP>;
        close TAP;
}

my $tapdata = TAP::DOM->new( tap => $tap );
#my $tapdata = tapdata( tap => $tap );
# print STDERR Dumper($tapdata);

is($tapdata->{tests_run},      8, "tests_run");
is($tapdata->{tests_planned},  6, "tests_planned");
is($tapdata->{version},       13, "version");
is($tapdata->{plan},      "1..6", "plan");

is($tapdata->{lines}[2]{number},  1,                               "[2] number");
is($tapdata->{lines}[2]{is_test}, 1,                               "[2] is_test");
is($tapdata->{lines}[2]{is_ok},   1,                               "[2] is_ok");
is($tapdata->{lines}[2]{raw},       "ok 1 - use Data::DPath;",     "[2] raw");
is($tapdata->{lines}[2]{as_string}, "ok 1 - use Data::DPath;",     "[2] as_string");

is($tapdata->lines->[2]->number,    1,                             "[2] number via methods");
is($tapdata->lines->[2]->is_test,   1,                             "[2] is_test via methods");
is($tapdata->lines->[2]->is_ok,     1,                             "[2] is_ok via methods");
is($tapdata->lines->[2]->raw,       "ok 1 - use Data::DPath;",     "[2] raw via methods");
is($tapdata->lines->[2]->as_string, "ok 1 - use Data::DPath;",     "[2] as_string via methods");

is($tapdata->{lines}[2]{_children}[0]{data}[0]{name}, "Hash one",     "[2]...{data}");
is($tapdata->lines->[2]->_children->[0]->data->[0]{name}, "Hash one",     "[2]...{data} via methods");

is($tapdata->{summary}{todo},         4,      "summary todo");
is($tapdata->{summary}{total},        8,      "summary total");
is($tapdata->{summary}{passed},       6,      "summary passed");
is($tapdata->{summary}{failed},       2,      "summary failed");
is($tapdata->{summary}{exit},         0,      "summary exit");
is($tapdata->{summary}{wait},         0,      "summary wait");
is($tapdata->{summary}{status},       "FAIL", "summary status");
is($tapdata->{summary}{all_passed},   0,      "summary all_passed");
is($tapdata->{summary}{has_problems}, 1,      "summary has_problems");

is($tapdata->summary->todo,         4,      "summary todo via methods");
is($tapdata->summary->total,        8,      "summary total via methods");
is($tapdata->summary->passed,       6,      "summary passed via methods");
is($tapdata->summary->failed,       2,      "summary failed via methods");
is($tapdata->summary->exit,         0,      "summary exit via methods");
is($tapdata->summary->wait,         0,      "summary wait via methods");
is($tapdata->summary->status,       "FAIL", "summary status via methods");
is($tapdata->summary->all_passed,   0,      "summary all_passed via methods");
is($tapdata->summary->has_problems, 1,      "summary has_problems via methods");

done_testing();
