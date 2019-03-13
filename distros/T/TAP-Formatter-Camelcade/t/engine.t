#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Cwd;
use v5.10;
use Time::HiRes qw/time/;

my $OVERWRITE_RESULTS = 0;

$ENV{TAP_FORMATTER_CAMELCADE_TIME} = '1552222609.97356';
$ENV{TAP_FORMATTER_CAMELCADE_DURATION} = 42;


sub check_results_with_file {
    my $test_name = shift;
    my $result = shift;

    $result =~ s/(^\s+|\r|\s+$)//gsi;
    $result =~ s/^##teamcity/teamcity/gm;
    if ($^O eq 'MSWin32') {
        $result =~ s{\\}{/}gs;
    }
    my $result_file_path = "testData/results/$test_name.txt";
    if (!$OVERWRITE_RESULTS && -f $result_file_path) {
        open my $if, $result_file_path || fail("Error creating output file: $result_file_path, $!");
        my $expected = join '', <$if>;
        close $if;
        $expected =~ s/(^\s+|\s+$)//gsi;
        is($result, $expected, $test_name);
    }
    else {
        open my $of, ">$result_file_path" || fail("Error creating output file: $result_file_path, $!");
        print $of $result;
        close $of;
        fail($test_name);
        print STDERR "Output file is missing. Created a $result_file_path\n";
    }
}

my $basic_command = 'prove --norc --formatter TAP::Formatter::Camelcade -m -l';

subtest 'Single thread' => sub {
    my @tests = map {
        s{^testData/tests/(.+?).t$}{$1};
        $_;
    } glob("testData/tests/*.t");

    plan tests => scalar @tests;

    foreach my $test (@tests) {
        check_results_with_file($test, scalar `$basic_command testData/tests/$test.t`);
    }
};
subtest 'Two threads' => sub {
    check_results_with_file('all_in_2threads', join '', sort `$basic_command -j2 testData/tests`)
};
subtest 'Three threads' => sub {
    check_results_with_file('all_in_3threads', join '', sort `$basic_command -j3 testData/tests`)
};
subtest 'Four threads' => sub {
    check_results_with_file('all_in_4threads', join '', sort `$basic_command -j4 testData/tests`)
};

done_testing();

