#!perl

use strict;
use warnings;

use Test::More;

require_ok('Test::Compile::Internal');
my $test = new_ok('Test::Compile::Internal');

# Run some of the basic meithods, with basic test conditions
# ..mostly just to ensure they get executed

my $result;

$result = $test->all_pl_files_ok('t/scripts/messWithLib.pl');
$test->ok($result, "all_pl_files_ok returns true value");

$result = $test->all_pm_files_ok('lib/');
$test->ok($result, "all_pm_files_ok returns true value");

$result = $test->all_files_ok();
$test->ok($result, "all_files_ok returns true value");

TODO: {
    local $TODO = "testing files that don't compile, cause the test to fail";

    $result = $test->all_files_ok('t/scripts/failure.pl');
    $test->ok($result, "failure.pl doesn't compile");

    $result = $test->all_files_ok('t/scripts/Fail.pm');
    $test->ok($result, "Fail doesn't compile");
}

# Fin...
$test->done_testing();
