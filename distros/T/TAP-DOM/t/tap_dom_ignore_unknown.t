#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use TAP::DOM;
use Data::Dumper;

my $tap;
{
        local $/;
        open (TAP, "< t/some_tap_doublecomments.txt") or die "Cannot read t/some_tap_doublecomments.txt";
        $tap = <TAP>;
        close TAP;
}

########################## Complete TAP-DOM ####################

#diag "\n=== complete TAP-DOM:";
my $tapdata = TAP::DOM->new( tap => $tap);

#diag Dumper($tapdata);
is($tapdata->{plan},             "1..3",      "plan");
is($tapdata->{tests_run},             3,      "tests_run");
is($tapdata->{tests_planned},         3,      "tests_planned");
is($tapdata->{version},              13,      "version");
is($tapdata->{summary}{todo},         0,      "summary todo");
is($tapdata->{summary}{total},        3,      "summary total");
is($tapdata->{summary}{passed},       3,      "summary passed");
is($tapdata->{summary}{failed},       0,      "summary failed");
is($tapdata->{summary}{exit},         0,      "summary exit");
is($tapdata->{summary}{wait},         0,      "summary wait");
is($tapdata->{summary}{status},       "PASS", "summary status");
is($tapdata->{summary}{all_passed},   1,      "summary all_passed");
is($tapdata->{summary}{has_problems}, 0,      "summary has_problems");
is($tapdata->{lines}[3]{number},      2,     "[3] number");
is($tapdata->{lines}[3]{is_test},     1,     "[3] is_test");
is($tapdata->{lines}[3]{is_ok},       1,     "[3] is_ok");
is($tapdata->{lines}[3]{raw},        "ok 2 - zomtec", "[3] raw");
is($tapdata->{lines}[3]{_children}[5]{data}[0]{name}, "Hash one", "[3]...{data}");
is($tapdata->{lines}[3]{_children}[6]{raw}, "# A comment I want to see in TAP-DOM", "[3]...{visible comment}");
is(scalar @{$tapdata->{lines}[3]{_children}}, 7, "number of children lines (yaml and comments)");
# non-TAP lines are included by default
is($tapdata->{lines}[4]{number},   undef,     "[4]!number");
is($tapdata->{lines}[4]{is_test},      0,     "[4]!is_test");
is($tapdata->{lines}[4]{is_ok},    undef,     "[4]!is_ok");
is($tapdata->{lines}[4]{is_unknown},   1,     "[4] is_unknown");
is($tapdata->{lines}[4]{raw},       "THIS IS NOT A TAP LINE",     "[4] raw");
#
is($tapdata->{lines}[5]{number},   undef,     "[5]!number");
is($tapdata->{lines}[5]{is_test},      0,     "[5]!is_test");
is($tapdata->{lines}[5]{is_ok},    undef,     "[5]!is_ok");
is($tapdata->{lines}[5]{is_unknown},   1,     "[5] is_unknown");
is($tapdata->{lines}[5]{raw},       "AND THIS ONE IS ALSO NOT A TAP LINE",     "[5] raw");
# Later TAP lines
is($tapdata->{lines}[6]{number},  3,     "[6] number");
is($tapdata->{lines}[6]{is_test}, 1,     "[6] is_test");
is($tapdata->{lines}[6]{is_ok},   1,     "[6] is_ok");
is($tapdata->{lines}[6]{raw},       "ok 3 - and another one",     "[6] raw");


########################## Without unknown lines ####################

#diag "\n=== TAP-DOM without unknown lines:";
my $tapdata2 = TAP::DOM->new( tap => $tap, ignoreunknown => 1 );

# beginning looks normal
my $P = 'ignoreunknown -';
is($tapdata2->{plan},             "1..3",      "$P plan");
is($tapdata2->{tests_run},             3,      "$P tests_run");
is($tapdata2->{tests_planned},         3,      "$P tests_planned");
is($tapdata2->{version},              13,      "$P version");
is($tapdata2->{summary}{todo},         0,      "$P summary todo");
is($tapdata2->{summary}{total},        3,      "$P summary total");
is($tapdata2->{summary}{passed},       3,      "$P summary passed");
is($tapdata2->{summary}{failed},       0,      "$P summary failed");
is($tapdata2->{summary}{exit},         0,      "$P summary exit");
is($tapdata2->{summary}{wait},         0,      "$P summary wait");
is($tapdata2->{summary}{status},       "PASS", "$P summary status");
is($tapdata2->{summary}{all_passed},   1,      "$P summary all_passed");
is($tapdata2->{summary}{has_problems}, 0,      "$P summary has_problems");
is($tapdata2->{lines}[3]{number},      2,     "$P [3] number");
is($tapdata2->{lines}[3]{is_test},     1,     "$P [3] is_test");
is($tapdata2->{lines}[3]{is_ok},       1,     "$P [3] is_ok");
is($tapdata2->{lines}[3]{raw},        "ok 2 - zomtec", "$P [3] raw");
is($tapdata2->{lines}[3]{_children}[5]{data}[0]{name}, "Hash one", "$P [3]...{data}");
is($tapdata2->{lines}[3]{_children}[6]{raw}, "# A comment I want to see in TAP-DOM", "$P [3]...{visible comment}");
is(scalar @{$tapdata2->{lines}[3]{_children}}, 7, "$P number of children lines (yaml and comments)");
# then the former late lines appear now earlier as we skipped the unknown
is($tapdata2->{lines}[4]{number},  3,     "$P [4] number");
is($tapdata2->{lines}[4]{is_test}, 1,     "$P [4] is_test");
is($tapdata2->{lines}[4]{is_ok},   1,     "$P [4] is_ok");
is($tapdata2->{lines}[4]{raw},       "ok 3 - and another one",     "$P [4] raw");

done_testing();
