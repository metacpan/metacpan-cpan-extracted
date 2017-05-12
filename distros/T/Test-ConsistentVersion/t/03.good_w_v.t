chdir 't/Sample-vGood';
use lib 'lib';

use Test::Builder::Tester tests => 2;
use Test::More;

my $expected_tests = 2;     #number of modules to check
my $testing_pod = eval {require Test::Pod::Content};
$expected_tests *= 2 if $testing_pod;
                            #double it if we are checking for pod versions
$expected_tests+=2;          #plus one each for the Changelog and README file

my $test_count = 1;
test_out(sprintf 'ok %d - Sample::vGood is the same as the distribution version', $test_count++);
test_out(sprintf 'ok %d - Sample::StillvGood is the same as the distribution version', $test_count++);
test_out(sprintf 'ok %d - Sample::vGood POD version is the same as module version', $test_count++) if $testing_pod;
test_out(sprintf 'ok %d - Sample::StillvGood POD version is the same as module version', $test_count++) if $testing_pod;
test_out(sprintf 'ok %d - Changelog includes reference to the distribution version: 1.2.31', $test_count++);
test_out(sprintf 'ok %d - README file includes reference to the distribution version: 1.2.31', $test_count++);

test_diag('Test::Pod::Content required to test POD version consistency') unless $testing_pod;
test_diag(q{Distribution version: 1.2.31});

use Test::ConsistentVersion;
my $T = Test::Builder->new;

Test::ConsistentVersion::check_consistent_versions();
my $tests_run = $T->current_test;
test_test('Failing version check');

is($tests_run, $expected_tests, "Expected number of tests ($expected_tests) were performed");

