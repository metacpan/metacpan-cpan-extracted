#!perl

use strict;
use warnings;

use Test::More;

require_ok('Test::Compile::Internal');
my $test = new_ok('Test::Compile::Internal');

# Some of the logic actually calls Test::More::ok
# ..test some conditions where that isn't going to work

my $result;

TODO: {
    local $TODO = "testing files that don't compile - causes the test to fail";

    $result = $test->all_files_ok('t/scripts/failure.pl');
    $test->ok($result, "failure.pl doesn't compile");

    $result = $test->all_files_ok('t/scripts/Fail.pm');
    $test->ok($result, "Fail doesn't compile");
}

# Fin...
$test->done_testing();
