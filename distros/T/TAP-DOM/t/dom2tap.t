#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use TAP::DOM;
use Data::Dumper;

sub check_tap
{
    my ($comment, $tapdata) = @_;

    is($tapdata->{tests_run},      8, "$comment - tests_run");
    is($tapdata->{tests_planned},  6, "$comment - tests_planned");
    is($tapdata->{version},       13, "$comment - version");
    is($tapdata->{plan},      "1..6", "$comment - plan");

    is($tapdata->{lines}[2]{number},  1,                               "$comment - [2] number");
    is($tapdata->{lines}[2]{is_test}, 1,                               "$comment - [2] is_test");
    is($tapdata->{lines}[2]{is_ok},   1,                               "$comment - [2] is_ok");
    is($tapdata->{lines}[2]{raw},       "ok 1 - use Data::DPath;",     "$comment - [2] raw");
    is($tapdata->{lines}[2]{as_string}, "ok 1 - use Data::DPath;",     "$comment - [2] as_string");

    is($tapdata->lines->[2]->number,    1,                             "$comment - [2] number via methods");
    is($tapdata->lines->[2]->is_test,   1,                             "$comment - [2] is_test via methods");
    is($tapdata->lines->[2]->is_ok,     1,                             "$comment - [2] is_ok via methods");
    is($tapdata->lines->[2]->raw,       "ok 1 - use Data::DPath;",     "$comment - [2] raw via methods");
    is($tapdata->lines->[2]->as_string, "ok 1 - use Data::DPath;",     "$comment - [2] as_string via methods");

    is($tapdata->{lines}[2]{_children}[0]{data}[0]{name}, "Hash one",     "$comment - [2]...{data}");
    is($tapdata->lines->[2]->_children->[0]->data->[0]{name}, "Hash one", "$comment - [2]...{data} via methods");

    is($tapdata->{summary}{todo},         4,      "$comment - summary todo");
    is($tapdata->{summary}{total},        8,      "$comment - summary total");
    is($tapdata->{summary}{passed},       6,      "$comment - summary passed");
    is($tapdata->{summary}{failed},       2,      "$comment - summary failed");
    is($tapdata->{summary}{exit},         0,      "$comment - summary exit");
    is($tapdata->{summary}{wait},         0,      "$comment - summary wait");
    is($tapdata->{summary}{status},       "FAIL", "$comment - summary status");
    is($tapdata->{summary}{all_passed},   0,      "$comment - summary all_passed");
    is($tapdata->{summary}{has_problems}, 1,      "$comment - summary has_problems");

    is($tapdata->summary->todo,         4,      "$comment - summary todo via methods");
    is($tapdata->summary->total,        8,      "$comment - summary total via methods");
    is($tapdata->summary->passed,       6,      "$comment - summary passed via methods");
    is($tapdata->summary->failed,       2,      "$comment - summary failed via methods");
    is($tapdata->summary->exit,         0,      "$comment - summary exit via methods");
    is($tapdata->summary->wait,         0,      "$comment - summary wait via methods");
    is($tapdata->summary->status,       "FAIL", "$comment - summary status via methods");
    is($tapdata->summary->all_passed,   0,      "$comment - summary all_passed via methods");
    is($tapdata->summary->has_problems, 1,      "$comment - summary has_problems via methods");
}

my $tap;
{
        local $/;
        open (TAP, "< t/some_tap.txt") or die "Cannot read t/some_tap.txt";
        $tap = <TAP>;
        close TAP;
}

my $tapdom = TAP::DOM->new( tap => $tap );
check_tap("original TAP", $tapdom);

my $tap2 = $tapdom->to_tap;
my $tapdom2 = TAP::DOM->new( tap => $tap2 );
check_tap("regenerated TAP", $tapdom2);

done_testing();
