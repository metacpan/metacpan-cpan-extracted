
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'lib/TAP/Formatter/Session/TeamCity.pm',
    'lib/TAP/Formatter/TeamCity.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/author-00-compile.t',
    't/author-eol.t',
    't/author-no-tabs.t',
    't/author-pod-spell.t',
    't/author-pod-syntax.t',
    't/author-test-version.t',
    't/basic.t',
    't/lib/TAP/Formatter/TeamCity/Test/ExitFast.pm',
    't/lib/TAP/Formatter/TeamCity/Test/OKNoMessage.pm',
    't/lib/TAP/Formatter/TeamCity/Test/SimpleFail.pm',
    't/lib/TAP/Formatter/TeamCity/Test/SimpleOK.pm',
    't/lib/TAP/Formatter/TeamCity/Test/SimpleSkip.pm',
    't/release-cpan-changes.t',
    't/release-pod-coverage.t',
    't/release-portability.t',
    't/release-tidyall.t',
    't/test-data/basic/exit-before-first-test/expected.txt',
    't/test-data/basic/exit-before-first-test/input.st',
    't/test-data/basic/ok-no-message/expected.txt',
    't/test-data/basic/ok-no-message/input.st',
    't/test-data/basic/simple-dies-mid-test/expected.txt',
    't/test-data/basic/simple-dies-mid-test/input.st',
    't/test-data/basic/simple-fail-comparison/expected.txt',
    't/test-data/basic/simple-fail-comparison/input.st',
    't/test-data/basic/simple-fail/expected.txt',
    't/test-data/basic/simple-fail/input.st',
    't/test-data/basic/simple-ok/expected.txt',
    't/test-data/basic/simple-ok/input.st',
    't/test-data/basic/skip-all/expected.txt',
    't/test-data/basic/skip-all/input.st',
    't/test-data/basic/subtest-dies-mid-test/expected.txt',
    't/test-data/basic/subtest-dies-mid-test/input.st',
    't/test-data/basic/subtest-ok/expected.txt',
    't/test-data/basic/subtest-ok/input.st',
    't/test-data/basic/subtest-todo/expected.txt',
    't/test-data/basic/subtest-todo/input.st',
    't/test-data/basic/tc-message-from-test/expected.txt',
    't/test-data/basic/tc-message-from-test/input.st',
    't/test-data/basic/test-class-moose-exit-before-tests/expected.txt',
    't/test-data/basic/test-class-moose-exit-before-tests/input.st',
    't/test-data/basic/test-class-moose-mixed/expected.txt',
    't/test-data/basic/test-class-moose-mixed/input.st',
    't/test-data/basic/test-class-moose-ok-no-message/expected.txt',
    't/test-data/basic/test-class-moose-ok-no-message/input.st',
    't/test-data/basic/test-class-moose-ok/expected.txt',
    't/test-data/basic/test-class-moose-ok/input.st',
    't/test-data/basic/test-class-moose-skip/expected.txt',
    't/test-data/basic/test-class-moose-skip/input.st',
    't/test-data/basic/test-name-matches-file/expected.txt',
    't/test-data/basic/test-name-matches-file/input.st',
    't/test-data/basic/use-error-before-test-more/expected.txt',
    't/test-data/basic/use-error-before-test-more/input.st'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
