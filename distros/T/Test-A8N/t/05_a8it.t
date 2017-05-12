#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
if (-f glob("~/.a8rc")) {
    plan(skip_all => "you can't run a8it unit tests if a ~/.a8rc file exists");
} else {
    plan(tests => 38);
}

my $a8it = "$^X -Iblib -It/lib scripts/a8it %s 2>&1";
sub runcmd {
    my $cmd = sprintf($a8it, @_);
    return `$cmd`;
}
sub generate_tap {
    my $str;
    my $count = 0;
    foreach my $testcount (map { split(//, $_) } @_) {
        foreach my $linenum (1 .. $testcount) {
            $str .= sprintf("ok %d - fixture%d\n", ++$count, $linenum);
        }
    }
    return "1..$count\n$str";
}

DashDash_help: {
    my $output;
    $output = runcmd("--help");
    ok($output =~ /^Usage:/s, "--help usage");
}

DashDash_version: {
    my $output;
    $output = runcmd("--version");
    ok($output =~ /^a8it version /, "--version info");
}

DashDash_file_root: {
    my $output;
    $output = runcmd("--file_root=t/testdata/empty");
    is($?, 0, "check error code");
    is($output, "", "expect empty output since no tests ran");

    $output = runcmd("--file_root=t/testdata/cases");
    is($?, 0, "check error code");
    like($output, qr/^1\.\.\d+/, "expect TAP output preamble for each file");
    is($output, generate_tap(4 x 6, 2 x 4), "check actual TAP output");

    $output = runcmd("--file_root=t/testdata/cases t/testdata/cases/test1.tc");
    is($?, 0, "single file: check error code");
    is($output, generate_tap(4), "single file: check actual TAP output");

    $output = runcmd("--file_root=t/testdata/cases t/testdata/cases/test1.tc t/testdata/cases/test_multiple.st");
    is($?, 0, "multiple files: check error code");
    is($output, generate_tap(4 x 4), "multiple files: check actual TAP output");
}

DashDash_verbose: {
    my $output;

    $output = runcmd("--file_root=t/testdata/cases -v t/testdata/cases/test1.tc");
    is($?, 0, "single verbose: check error code");
    is($output, <<EOF, "single verbose: check actual TAP output");
1..4
# START: "t/testdata/cases/test1.tc": some_test_case_1
ok 1 - fixture1
ok 2 - fixture2
ok 3 - fixture3
ok 4 - fixture4
# FINISH: "t/testdata/cases/test1.tc": some_test_case_1
EOF

    $output = runcmd("--file_root=t/testdata/cases -v -v t/testdata/cases/test1.tc");
    is($?, 0, "double verbose: check error code");
    is($output, <<EOF, "double verbose: check actual TAP output");
1..4
# Using fixture class "Fixture"
# START: "t/testdata/cases/test1.tc": some_test_case_1
# Fixture method fixture1
# Fixture method fixture2
# Fixture method fixture3
# Fixture method fixture4
# Fixture method fixture1
ok 1 - fixture1
# Fixture method fixture2
ok 2 - fixture2
# Fixture method fixture3
ok 3 - fixture3
# Fixture method fixture4
ok 4 - fixture4
# FINISH: "t/testdata/cases/test1.tc": some_test_case_1
EOF

    $output = runcmd("--file_root=t/testdata/cases -v -v -v t/testdata/cases/test1.tc");
    is($?, 0, "triple verbose: check error code");
    is($output, <<EOF, "triple verbose: check actual TAP output");
# Attempting to load fixture class Fixture
1..4
# Using fixture class "Fixture"
# START: "t/testdata/cases/test1.tc": some_test_case_1
# Fixture method fixture1
# Fixture method fixture2
# Fixture method fixture3
# Fixture method fixture4
# Fixture method fixture1
ok 1 - fixture1
# Fixture method fixture2
ok 2 - fixture2
# Fixture method fixture3
ok 3 - fixture3
# Fixture method fixture4
ok 4 - fixture4
# FINISH: "t/testdata/cases/test1.tc": some_test_case_1
EOF

    $output = runcmd("--file_root=t/testdata/cases -v t/testdata/cases/invalid_syntax.tc");
    is($?, 0, "single verbose: check error code");
    like($output, qr{# YAML syntax error while loading t/testdata/cases/invalid_syntax\.tc}, "Invalid file produces error message with verbose");
}

DashDash_list: {
    my $output;

    $output = runcmd("--file_root=t/testdata/cases --list t/testdata/cases/test1.tc");
    is($?, 0, "list test1.tc: check error code");
    is($output, <<EOF, "list test1.tc: check output");
t/testdata/cases/test1.tc => some_test_case_1
EOF

    $output = runcmd("--file_root=t/testdata/cases --list t/testdata/cases/test_multiple.st");
    is($?, 0, "list test_multiple.st: check error code");
    is($output, <<EOF, "list test_multiple.st: check output");
t/testdata/cases/test_multiple.st => test_case_1
t/testdata/cases/test_multiple.st => custom_id
t/testdata/cases/test_multiple.st => some_other_id
EOF

    $output = runcmd("--file_root=t/testdata/cases --list --id=test_case_1 t/testdata/cases/test_multiple.st");
    is($?, 0, "id arg: check error code");
    is($output, <<EOF, "id arg: check output");
t/testdata/cases/test_multiple.st => test_case_1
EOF

    $output = runcmd("--file_root=t/testdata/cases --list --tag=tag1 t/testdata/cases/test_multiple.st");
    is($?, 0, "single tag: check error code");
    is($output, <<EOF, "single tag: check output");
t/testdata/cases/test_multiple.st => test_case_1
t/testdata/cases/test_multiple.st => custom_id
EOF

    $output = runcmd("--file_root=t/testdata/cases --list --tag=tag1 --tag=tag2 t/testdata/cases/test_multiple.st");
    is($?, 0, "multiple tags: check error code");
    is($output, <<EOF, "multiple tags: check output");
t/testdata/cases/test_multiple.st => test_case_1
EOF

    $output = runcmd("--file_root=t/testdata/cases --list --tag=tag1 --tag=!tag2 t/testdata/cases/test_multiple.st");
    is($?, 0, "exclude tag: check error code");
    is($output, <<EOF, "exclude tag: check output");
t/testdata/cases/test_multiple.st => custom_id
EOF
}

DashDash_config: {
    my $output;
    $output = runcmd("--config=t/data/config1");
    is($?, 0, "check error code");
    is($output, "", "expect empty output since no tests ran");

    $output = runcmd("--config=t/data/config2");
    is($?, 0, "check error code");
    is($output, generate_tap(4 x 6, 2 x 4), "expect lots of TAP output");
}

SKIP: {
    skip "Running test cases with a shebang hangs for some reason", 3;
    Shebang: {
        my $filename = "t/testdata/cases/test_multiple.st";
        SKIP: {
            skip "test file is already executable", 1 if (-x $filename);
            chmod 0755, $filename;
            ok(-x $filename, "test file is executable");
        }

        my $output = `$filename 2>&1`;
        is($?, 0, "check error code");
        is($output, generate_tap(4 x 3), "expect one test file worth of TAP output");
    }
}
