
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
    'lib/Test/DependentModules.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/author-00-compile.t',
    't/author-all-my-deps.t',
    't/author-configure-requires.t',
    't/author-eol.t',
    't/author-mojibake.t',
    't/author-no-tabs.t',
    't/author-pod-spell.t',
    't/author-pod-syntax.t',
    't/author-single-distros.t',
    't/author-test-version.t',
    't/author-two-distros.t',
    't/basic.t',
    't/release-cpan-changes.t',
    't/release-pod-coverage.t',
    't/release-pod-linkcheck.t',
    't/release-pod-no404s.t',
    't/release-portability.t',
    't/release-tidyall.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
