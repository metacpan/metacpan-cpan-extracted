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

# diag "\n=== complete TAP-DOM:";
my $tapdata = TAP::DOM->new( tap => $tap); # needs Test::Harness 3.22: , version => 13 );

#diag Dumper($tapdata);
is($tapdata->{tests_run},     3,     "tests_run");
is($tapdata->{tests_planned},  3,     "tests_planned");
is($tapdata->{version},       13,     "version");
is($tapdata->{plan},          "1..3", "plan");
is($tapdata->{lines}[3]{number},  2,     "[2] number");
is($tapdata->{lines}[3]{is_test}, 1,     "[2] is_test");
is($tapdata->{lines}[3]{is_ok},   1,     "[2] is_ok");
is($tapdata->{lines}[3]{raw},       "ok 2 - zomtec",     "[2] raw");
is($tapdata->{lines}[3]{_children}[5]{data}[0]{name}, "Hash one",     "[2]...{data}");
is($tapdata->{lines}[3]{_children}[6]{raw}, "# A comment I want to see in TAP-DOM", "[2]...{visible comment}");
is(scalar @{$tapdata->{lines}[3]{_children}}, 7, "number of children lines (yaml and comments)");
is($tapdata->{summary}{todo},         0,      "summary todo");
is($tapdata->{summary}{total},        3,      "summary total");
is($tapdata->{summary}{passed},       3,      "summary passed");
is($tapdata->{summary}{failed},       0,      "summary failed");
is($tapdata->{summary}{exit},         0,      "summary exit");
is($tapdata->{summary}{wait},         0,      "summary wait");
is($tapdata->{summary}{status},       "PASS", "summary status");
is($tapdata->{summary}{all_passed},   1,      "summary all_passed");
is($tapdata->{summary}{has_problems}, 0,      "summary has_problems");
is($tapdata->{lines}[6]{number},  3,     "[3] number");
is($tapdata->{lines}[6]{is_test}, 1,     "[3] is_test");
is($tapdata->{lines}[6]{is_ok},   1,     "[3] is_ok");
is($tapdata->{lines}[6]{raw},       "ok 3 - and another one",     "[3] raw");


# diag "\n=== complete TAP-DOM with pre-processing TAP:";
my $tapdata2 = TAP::DOM->new( tap => $tap, preprocess_tap => 1 );

#diag Dumper($tapdata2);
is($tapdata2->{tests_run},     3,     "tests_run");
is($tapdata2->{tests_planned},  3,     "tests_planned");
is($tapdata2->{version},       13,     "version");
is($tapdata2->{plan},          "1..3", "plan");
is($tapdata2->{lines}[3]{number},  2,     "[2] number");
is($tapdata2->{lines}[3]{is_test}, 1,     "[2] is_test");
is($tapdata2->{lines}[3]{is_ok},   1,     "[2] is_ok");
is($tapdata2->{lines}[3]{raw},       "ok 2 - zomtec",     "[2] raw");
is($tapdata2->{lines}[3]{_children}[5]{data}[0]{name}, "Hash one",     "[2]...{data}");
is($tapdata2->{lines}[3]{_children}[6]{raw}, "# A comment I want to see in TAP-DOM", "[2]...{visible comment}");
is(scalar @{$tapdata2->{lines}[3]{_children}}, 7, "number of children lines (yaml and comments)");
is($tapdata2->{summary}{todo},         0,      "summary todo");
is($tapdata2->{summary}{total},        3,      "summary total");
is($tapdata2->{summary}{passed},       3,      "summary passed");
is($tapdata2->{summary}{failed},       0,      "summary failed");
is($tapdata2->{summary}{exit},         0,      "summary exit");
is($tapdata2->{summary}{wait},         0,      "summary wait");
is($tapdata2->{summary}{status},       "PASS", "summary status");
is($tapdata2->{summary}{all_passed},   1,      "summary all_passed");
is($tapdata2->{summary}{has_problems}, 0,      "summary has_problems");
is($tapdata2->{lines}[4]{number},  3,     "[3] number");
is($tapdata2->{lines}[4]{is_test}, 1,     "[3] is_test");
is($tapdata2->{lines}[4]{is_ok},   1,     "[3] is_ok");
is($tapdata2->{lines}[4]{raw},       "ok 3 - and another one",     "[3] raw");


# diag "\n=== terse TAP-DOM without pre-process:";
$tapdata2 = TAP::DOM->new( tap => $tap, ignorelines => qr/^## / ); # sic! use qr// here

# diag Dumper($tapdata2);
is($tapdata2->{tests_run},     3,     "tests_run");
is($tapdata2->{tests_planned},  3,     "tests_planned");
is($tapdata2->{version},       13,     "version");
is($tapdata2->{plan},          "1..3", "plan");
is($tapdata2->{lines}[3]{number},  2,     "[2] number");
is($tapdata2->{lines}[3]{is_test}, 1,     "[2] is_test");
is($tapdata2->{lines}[3]{is_ok},   1,     "[2] is_ok");
is($tapdata2->{lines}[3]{raw},       "ok 2 - zomtec",     "[2] raw");
is($tapdata2->{lines}[3]{_children}[0]{data}[0]{name}, "Hash one",     "[2]...{data}");
is($tapdata2->{lines}[3]{_children}[1]{raw}, "# A comment I want to see in TAP-DOM", "[2]...{visible comment}");
is(scalar @{$tapdata2->{lines}[3]{_children}}, 2, "number of children lines (yaml and comments)");
is($tapdata2->{summary}{todo},         0,      "summary todo");
is($tapdata2->{summary}{total},        3,      "summary total");
is($tapdata2->{summary}{passed},       3,      "summary passed");
is($tapdata2->{summary}{failed},       0,      "summary failed");
is($tapdata2->{summary}{exit},         0,      "summary exit");
is($tapdata2->{summary}{wait},         0,      "summary wait");
is($tapdata2->{summary}{status},       "PASS", "summary status");
is($tapdata2->{summary}{all_passed},   1,      "summary all_passed");
is($tapdata2->{summary}{has_problems}, 0,      "summary has_problems");
is($tapdata2->{lines}[6]{number},  3,     "[3] number");
is($tapdata2->{lines}[6]{is_test}, 1,     "[3] is_test");
is($tapdata2->{lines}[6]{is_ok},   1,     "[3] is_ok");
is($tapdata2->{lines}[6]{raw},       "ok 3 - and another one",     "[3] raw");


# diag "\n=== terse TAP-DOM with pre-process tap:";
$tapdata2 = TAP::DOM->new( tap => $tap, ignorelines => '^## ', preprocess_ignorelines => 1 );

# diag Dumper($tapdata2);
is($tapdata2->{tests_run},     3,     "tests_run");
is($tapdata2->{tests_planned},  3,     "tests_planned");
is($tapdata2->{version},       13,     "version");
is($tapdata2->{plan},          "1..3", "plan");
is($tapdata2->{lines}[3]{number},  2,     "[2] number");
is($tapdata2->{lines}[3]{is_test}, 1,     "[2] is_test");
is($tapdata2->{lines}[3]{is_ok},   1,     "[2] is_ok");
is($tapdata2->{lines}[3]{raw},       "ok 2 - zomtec",     "[2] raw");
is($tapdata2->{lines}[3]{_children}[0]{data}[0]{name}, "Hash one",     "[2]...{data}");
is($tapdata2->{lines}[3]{_children}[1]{raw}, "# A comment I want to see in TAP-DOM", "[2]...{visible comment}");
is(scalar @{$tapdata2->{lines}[3]{_children}}, 2, "number of children lines (yaml and comments) is 2");
is($tapdata2->{summary}{todo},         0,      "summary todo");
is($tapdata2->{summary}{total},        3,      "summary total");
is($tapdata2->{summary}{passed},       3,      "summary passed");
is($tapdata2->{summary}{failed},       0,      "summary failed");
is($tapdata2->{summary}{exit},         0,      "summary exit");
is($tapdata2->{summary}{wait},         0,      "summary wait");
is($tapdata2->{summary}{status},       "PASS", "summary status");
is($tapdata2->{summary}{all_passed},   1,      "summary all_passed");
is($tapdata2->{summary}{has_problems}, 0,      "summary has_problems");
is($tapdata2->{lines}[6]{number},  3,     "[3] number");
is($tapdata2->{lines}[6]{is_test}, 1,     "[3] is_test");
is($tapdata2->{lines}[6]{is_ok},   1,     "[3] is_ok");
is($tapdata2->{lines}[6]{raw},       "ok 3 - and another one",     "[3] raw");


# diag "\n=== terse TAP-DOM with pre-process tap:";
$tapdata2 = TAP::DOM->new( tap => $tap, ignorelines => '^## ', preprocess_ignorelines => 1, preprocess_tap => 1 );

# diag Dumper($tapdata2);
is($tapdata2->{tests_run},     3,     "tests_run");
is($tapdata2->{tests_planned},  3,     "tests_planned");
is($tapdata2->{version},       13,     "version");
is($tapdata2->{plan},          "1..3", "plan");
is($tapdata2->{lines}[3]{number},  2,     "[2] number");
is($tapdata2->{lines}[3]{is_test}, 1,     "[2] is_test");
is($tapdata2->{lines}[3]{is_ok},   1,     "[2] is_ok");
is($tapdata2->{lines}[3]{raw},       "ok 2 - zomtec",     "[2] raw");
is($tapdata2->{lines}[3]{_children}[0]{data}[0]{name}, "Hash one",     "[2]...{data}");
is($tapdata2->{lines}[3]{_children}[1]{raw}, "# A comment I want to see in TAP-DOM", "[2]...{visible comment}");
is(scalar @{$tapdata2->{lines}[3]{_children}}, 2, "number of children lines (yaml and comments)");
is($tapdata2->{summary}{todo},         0,      "summary todo");
is($tapdata2->{summary}{total},        3,      "summary total");
is($tapdata2->{summary}{passed},       3,      "summary passed");
is($tapdata2->{summary}{failed},       0,      "summary failed");
is($tapdata2->{summary}{exit},         0,      "summary exit");
is($tapdata2->{summary}{wait},         0,      "summary wait");
is($tapdata2->{summary}{status},       "PASS", "summary status");
is($tapdata2->{summary}{all_passed},   1,      "summary all_passed");
is($tapdata2->{summary}{has_problems}, 0,      "summary has_problems");
is($tapdata2->{lines}[4]{number},  3,     "[3] number");
is($tapdata2->{lines}[4]{is_test}, 1,     "[3] is_test");
is($tapdata2->{lines}[4]{is_ok},   1,     "[3] is_ok");
is($tapdata2->{lines}[4]{raw},       "ok 3 - and another one",     "[3] raw");

done_testing();
