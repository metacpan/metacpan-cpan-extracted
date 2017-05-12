#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use TAP::DOM;
use Data::Dumper;

my $tap;
{
        local $/;
        open (TAP, "< t/some_tap.txt") or die "Cannot read t/some_tap.txt";
        $tap = <TAP>;
        close TAP;
}

# =========== strip some details ============================================

my $tapdata = TAP::DOM->new( tap    => $tap,
                            ignore => [qw(raw as_string explanation)],
                          );
#my $tapdata = tapdata( tap => $tap );
# diag Dumper $tapdata;

is($tapdata->{tests_run},     8,     "tests_run");
is($tapdata->{tests_planned},  6,     "tests_planned");
is($tapdata->{version},       13,     "version");
is($tapdata->{plan},          "1..6", "plan");

is($tapdata->{lines}[2]{number},  1,     "[2] number");
is($tapdata->{lines}[2]{is_test}, 1,     "[2] is_test");
is($tapdata->{lines}[2]{is_ok},   1,     "[2] is_ok");
isnt($tapdata->{lines}[2]{raw},       "ok 1 - use Data::DPath;",     "[2] stripped raw");
isnt($tapdata->{lines}[2]{as_string}, "ok 1 - use Data::DPath;",     "[2] stripped as_string");
ok((not defined $tapdata->{lines}[2]{raw}),       "[2] undefined raw");
ok((not defined $tapdata->{lines}[2]{as_string}), "[2] undefined as_string");

isnt($tapdata->{lines}[6]{explanation}, "spec only", "[6] stripped explanation");
ok((not defined $tapdata->{lines}[6]{explanation}), "[2] undefined expla");

is($tapdata->{lines}[2]{_children}[0]{data}[0]{name}, "Hash one",     "[2]...{data}");

is($tapdata->{summary}{todo},         4,      "summary todo");
is($tapdata->{summary}{total},        8,      "summary total");
is($tapdata->{summary}{passed},       6,      "summary passed");
is($tapdata->{summary}{failed},       2,      "summary failed");
is($tapdata->{summary}{exit},         0,      "summary exit");
is($tapdata->{summary}{wait},         0,      "summary wait");
is($tapdata->{summary}{status},       "FAIL", "summary status");
is($tapdata->{summary}{all_passed},   0,      "summary all_passed");
is($tapdata->{summary}{has_problems}, 1,      "summary has_problems");

# =========== normal ======================================================

$tapdata = TAP::DOM->new( tap => $tap );
#my $tapdata = tapdata( tap => $tap );
# print STDERR Dumper($tapdata);

is($tapdata->{tests_run},     8,     "tests_run");
is($tapdata->{tests_planned},  6,     "tests_planned");
is($tapdata->{version},       13,     "version");
is($tapdata->{plan},          "1..6", "plan");

is($tapdata->{lines}[2]{number},  1,     "[2] number");
is($tapdata->{lines}[2]{is_test}, 1,     "[2] is_test");
is($tapdata->{lines}[2]{is_ok},   1,     "[2] is_ok");
is($tapdata->{lines}[2]{is_ok},   1,     "[2] is_ok");
is($tapdata->{lines}[2]{raw},       "ok 1 - use Data::DPath;",     "[2] raw");
is($tapdata->{lines}[2]{as_string}, "ok 1 - use Data::DPath;",     "[2] as_string");

is($tapdata->{lines}[6]{explanation}, "spec only 1", "[6] explanation");

is($tapdata->{lines}[2]{_children}[0]{data}[0]{name}, "Hash one",     "[2]...{data}");

is($tapdata->{summary}{todo},         4,      "summary todo");
is($tapdata->{summary}{total},        8,      "summary total");
is($tapdata->{summary}{passed},       6,      "summary passed");
is($tapdata->{summary}{failed},       2,      "summary failed");
is($tapdata->{summary}{exit},         0,      "summary exit");
is($tapdata->{summary}{wait},         0,      "summary wait");
is($tapdata->{summary}{status},       "FAIL", "summary status");
is($tapdata->{summary}{all_passed},   0,      "summary all_passed");
is($tapdata->{summary}{has_problems}, 1,      "summary has_problems");

done_testing();
