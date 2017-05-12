#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use TAP::DOM;
use Data::Dumper;

BEGIN {
        if ($TAP::Parser::VERSION < 3.22) {
                plan skip_all => "TAP::Parser 3.22 required for setting TAP version. This is ".$TAP::Parser::VERSION.".";
        }
}

my $tap;
{
        local $/;
        open (TAP, "< t/some_tap6_autotapversion.txt") or die "Cannot read t/some_tap6_autotapversion.txt";
        $tap = <TAP>;
        close TAP;
}

my $tapdata = TAP::DOM->new( tap => $tap, version => 13 );
# diag Dumper $tapdata;

is($tapdata->{tests_run},      2, "tests_run");
is($tapdata->{tests_planned},  2, "tests_planned");
is($tapdata->{version},       13, "version");
is($tapdata->{plan},      "1..2", "plan");

is($tapdata->{lines}[1]{_children}[0]{data}{BenchmarkAnythingData}[0]{NAME},  "bogomips", "BenchmarkAnythingData.NAME");
is($tapdata->{lines}[1]{_children}[0]{data}{BenchmarkAnythingData}[0]{VALUE}, "9876.50",  "BenchmarkAnythingData.VALUE");

is($tapdata->{summary}{todo},         0,      "summary todo");
is($tapdata->{summary}{total},        2,      "summary total");
is($tapdata->{summary}{passed},       2,      "summary passed");
is($tapdata->{summary}{failed},       0,      "summary failed");
is($tapdata->{summary}{exit},         0,      "summary exit");
is($tapdata->{summary}{wait},         0,      "summary wait");
is($tapdata->{summary}{status},       "PASS", "summary status");
is($tapdata->{summary}{all_passed},   1,      "summary all_passed");
is($tapdata->{summary}{has_problems}, 0,      "summary has_problems");

is($tapdata->summary->todo,         0,      "summary todo via methods");
is($tapdata->summary->total,        2,      "summary total via methods");
is($tapdata->summary->passed,       2,      "summary passed via methods");
is($tapdata->summary->failed,       0,      "summary failed via methods");
is($tapdata->summary->exit,         0,      "summary exit via methods");
is($tapdata->summary->wait,         0,      "summary wait via methods");
is($tapdata->summary->status,       "PASS", "summary status via methods");
is($tapdata->summary->all_passed,   1,      "summary all_passed via methods");
is($tapdata->summary->has_problems, 0,      "summary has_problems via methods");

done_testing;
