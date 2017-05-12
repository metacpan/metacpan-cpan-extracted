chdir 't/Sample-Bad';
use lib 'lib';

use Test::Builder::Tester tests => 2;
use Test::More;

my $expected_tests = 2;     #number of modules to check
my $testing_pod = eval {require Test::Pod::Content};
$expected_tests *= 2 if $testing_pod;
                            #double it if we are checking for pod versions
$expected_tests += 2; #changelog and readme
use Test::ConsistentVersion;

my $RE_DEFAULT_FLAGS = qr// eq '(?-xism:)' ? 'i-xsm' : '^i';

my $test_count = 1;
test_out(sprintf 'ok %d - Sample::Bad is the same as the distribution version', $test_count++);
test_out(sprintf 'not ok %d - Sample::StillBad is the same as the distribution version', $test_count++);
test_out(sprintf 'not ok %d - Sample::Bad POD version is the same as module version', $test_count++) if $testing_pod;
test_out(sprintf 'ok %d - Sample::StillBad POD version is the same as module version', $test_count++) if $testing_pod;
test_out(sprintf 'not ok %d - Changelog includes reference to the distribution version: 1.2.31', $test_count++);
test_out(sprintf 'not ok %d - Unable to find README file', $test_count++);

test_diag('Test::Pod::Content required to test POD version consistency') unless $testing_pod;
test_diag(q{Distribution version: 1.2.31});

# Sample::StillBad has a different version number
test_err(q{#   Failed test 'Sample::StillBad is the same as the distribution version'});
test_err(q{#   at lib/Test/ConsistentVersion.pm line 45.});
test_err(q{#          got: '1.2.30'});
test_err(q{#     expected: '1.2.31'});

# Sample::Bad has different POD to the module version
if($testing_pod)
{
    test_err(q{#   Failed test 'Sample::Bad POD version is the same as module version'});
    test_err(sprintf '/#\s+ at .+%s .+/', quotemeta 'Test/Pod/Content.pm');
    test_err(q{#                   '1.2.30'});
    test_err(sprintf q{#     doesn't match '(?%s:(^|\s)v?1\.2\.31(\s|$))'}, $RE_DEFAULT_FLAGS);
}

# Changelog doesn't have the current version
test_err(q{#   Failed test 'Changelog includes reference to the distribution version: 1.2.31'});
test_err(q{#   at lib/Test/ConsistentVersion.pm line 47.});
test_err(q{#                   'Changelog});
test_err(q{# });
test_err(q{# });
test_err(q{# });
test_err(q{# 1.2.30});
test_err(q{# });
test_err(q{#     First version.});
test_err(q{# '});
test_err(sprintf q{#     doesn't match '(?%s:\bv?1\.2\.31\b)'}, $RE_DEFAULT_FLAGS);

# No readme file:
test_err(q{#   Failed test 'Unable to find README file'});
test_err(q{#   at lib/Test/ConsistentVersion.pm line 48.});
Test::ConsistentVersion::check_consistent_versions();
my $T = Test::Builder->new;
my $tests_run = $T->current_test;
test_test('Failing version check');

is($tests_run, $expected_tests, 'Expected number of tests were run')
