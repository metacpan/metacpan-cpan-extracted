#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 8;
use Test::Bot;
use Test::Bot::GitHub;

my $sample_tests_dir = "$FindBin::Bin/../sample_tests";

run_tests('all_good', 2, 0, 0);
run_tests('mixed', 2, 1, 2);
done_testing();

sub run_tests {
    my ($subdir, $expected_pass, $expected_fail, $expected_exit) = @_;
    
    my $bot = Test::Bot::GitHub->new_with_options(
        source_dir => $sample_tests_dir,
        tests_dir => $subdir,
        test_harness_module => 'Aggregate',
        notification_modules => [],
        force => 0,
    );

    $bot->configure_test_harness(
        aggregate_verbosity => -3,
    );

    # verify test input files
    my @test_files = sort { $a cmp $b } glob("$sample_tests_dir/$subdir/*.t");
    my @harness_test_files = sort { $a cmp $b } @{ $bot->test_files };
    is_deeply(\@test_files, \@harness_test_files, "got test files");

    # make fake commit, run tests for it
    my $commit = Test::Bot::Commit->new(
        id => $subdir,
        message => "testing $subdir",
    );

    $bot->run_tests_for_commit($commit);
    is(scalar(@{ $commit->passed }), $expected_pass, "$expected_pass passed");
    is(scalar(@{ $commit->exited }), $expected_exit, "$expected_exit exited");
    is(scalar(@{ $commit->failed }), $expected_fail, "$expected_fail failed");
}
