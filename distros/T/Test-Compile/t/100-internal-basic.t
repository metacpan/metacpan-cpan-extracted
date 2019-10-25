#!perl

use strict;
use warnings;

use Test::More;

require_ok('Test::Compile::Internal');
my $test = new_ok('Test::Compile::Internal');

# Run some of the basic meithods, with basic test conditions
# ..mostly just to ensure they get executed
my $result = $test->all_pl_files_ok('t/scripts/lib.pl');
$test->ok($result, "all_pl_files_ok returns true value");

$result = $test->all_pm_files_ok('lib/');
$test->ok($result, "all_pm_files_ok returns true value");

$result = $test->all_files_ok();
$test->ok($result, "all_files_ok returns true value");

# Fin...
$test->done_testing();
