#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;

use TAP::DOM ':constants';
use Data::Dumper;

my $tap;
{
        local $/;
        open (TAP, "< t/some_tap5_usebitsets.txt") or die "Cannot read t/some_tap5_usebitsets.txt";
        $tap = <TAP>;
        close TAP;
}

# ============================== without bitsets ==============================

my $tapdata = TAP::DOM->new( tap => $tap, usebitsets => 0 );
# diag Dumper($tapdata);

is($tapdata->{tests_run},      4, "tests_run");
is($tapdata->{tests_planned},  4, "tests_planned");
is($tapdata->{version},       13, "version");
is($tapdata->{plan},      "1..4", "plan");

is($tapdata->{lines}[2]{number},      1,          "[2] number");
like($tapdata->{lines}[2]{description}, qr/affe/, "[2] description");
is($tapdata->{lines}[2]{is_test},     1,          "[2] is_test");
is($tapdata->{lines}[2]{is_ok},       1,          "[2] is_ok");
is($tapdata->{lines}[2]{has_todo},    0,          "[2] has_todo");
is($tapdata->{lines}[2]{is_actual_ok}, 0,      "[2] is_actual_ok");
# diag Dumper ($tapdata->{lines}[2]{has_todo});

is($tapdata->{lines}[3]{number},   2,      "[3] number");
like($tapdata->{lines}[3]{description}, qr/test.*driven.*A/, "[3] description");
is($tapdata->{lines}[3]{is_test},  1,      "[3] is_test");
is($tapdata->{lines}[3]{is_ok},    1,      "[3] is_ok");
is($tapdata->{lines}[3]{has_todo}, 1,      "[3] has_todo");
is($tapdata->{lines}[3]{is_actual_ok}, 1,      "[3] is_actual_ok");

is($tapdata->{lines}[4]{number},       3,      "[4] number");
like($tapdata->{lines}[4]{description}, qr/test.*driven.*B/, "[4] description");
is($tapdata->{lines}[4]{is_test},      1,      "[4] is_test");
is($tapdata->{lines}[4]{is_ok},        1,      "[4] is_ok");
is($tapdata->{lines}[4]{has_todo},     1,      "[4] has_todo");
is($tapdata->{lines}[4]{is_actual_ok}, 0,      "[4] is_actual_ok");

is($tapdata->{lines}[5]{number},       4,      "[5] number");
like($tapdata->{lines}[5]{description}, qr/zomtec/, "[5] description");
is($tapdata->{lines}[5]{is_test},      1,      "[5] is_test");
is($tapdata->{lines}[5]{is_ok},        1,      "[5] is_ok");
is($tapdata->{lines}[5]{has_todo},     0,      "[5] has_todo");
is($tapdata->{lines}[5]{is_actual_ok}, 0,      "[5] is_actual_ok");

# ============================== use bitsets ==============================

$tapdata = TAP::DOM->new( tap => $tap, usebitsets => 1 );
# diag Dumper($tapdata);

is($tapdata->{tests_run},      4, "tests_run");
is($tapdata->{tests_planned},  4, "tests_planned");
is($tapdata->{version},       13, "version");
is($tapdata->{plan},      "1..4", "plan");

is($tapdata->{tapdom_config}{usebitsets}, 1, "tapdom_config usebitsets");
is($tapdata->tapdom_config->usebitsets, 1, "tapdom_config usebitsets via method");

like($tapdata->{lines}[2]{description}, qr/affe/,      "[2] description");
is($tapdata->{lines}[2]{number},        1,             "[2] number");
ok($tapdata->{lines}[2]{is_has} & $TAP::DOM::IS_TEST,  "[2] is_test (check bit using full namespace constant)");
ok($tapdata->{lines}[2]{is_has} & $IS_TEST,            "[2] is_test (check bit using exported constant)");
ok($tapdata->{lines}[2]->is_test,                      "[2] is_test (check bit using method)");
ok($tapdata->{lines}[2]{is_has} & $IS_OK,              "[2] is_ok");
ok(!($tapdata->{lines}[2]{is_has} & $HAS_TODO),           "[2] has_todo");
ok(!($tapdata->{lines}[2]{is_has} & $IS_ACTUAL_OK),       "[2] is_actual_ok");
# diag Dumper {
#     is_has            => $tapdata->{lines}[2]{is_has},
#     HAS_TODO          => $HAS_TODO,
#     "is_has&HAS_TODO" => ($tapdata->{lines}[2]{is_has} & $HAS_TODO),
# };

like($tapdata->{lines}[3]{description}, qr/test.*driven.*A/, "[3] description");
is($tapdata->{lines}[3]{number},        2,                   "[3] number");
ok($tapdata->{lines}[3]{is_has} & $IS_TEST,                  "[3] is_test");
ok($tapdata->{lines}[3]{is_has} & $IS_OK,                    "[3] is_ok");
ok($tapdata->{lines}[3]{is_has} & $HAS_TODO,                 "[3] has_todo");
ok($tapdata->{lines}[3]{is_has} & $IS_ACTUAL_OK,             "[3] is_actual_ok");

like($tapdata->{lines}[4]{description}, qr/test.*driven.*B/, "[4] description");
is($tapdata->{lines}[4]{number},        3,                   "[4] number");
ok($tapdata->{lines}[4]{is_has}  & $IS_TEST,                 "[4] is_test");
ok($tapdata->{lines}[4]{is_has}  & $IS_OK,                   "[4] is_ok");
ok($tapdata->{lines}[4]{is_has}  & $HAS_TODO,                "[4] has_todo");
ok(!($tapdata->{lines}[4]{is_has} & $IS_ACTUAL_OK),          "[4] is_actual_ok");

like($tapdata->{lines}[5]{description}, qr/zomtec/,          "[5] description");
is($tapdata->{lines}[5]{number},       4,                    "[5] number");
ok($tapdata->{lines}[5]{is_has}  & $IS_TEST,                 "[5] is_test");
ok($tapdata->{lines}[5]{is_has}  & $IS_OK,                   "[5] is_ok");
ok(!($tapdata->{lines}[5]{is_has} & $HAS_TODO),              "[5] has_todo");
ok(!($tapdata->{lines}[5]{is_has} & $IS_ACTUAL_OK),          "[5] is_actual_ok");

done_testing();
