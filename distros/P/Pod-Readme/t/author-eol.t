
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.19

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/pod2readme',
    'lib/Pod/Readme.pm',
    'lib/Pod/Readme/Filter.pm',
    'lib/Pod/Readme/Plugin.pm',
    'lib/Pod/Readme/Plugin/changes.pm',
    'lib/Pod/Readme/Plugin/requires.pm',
    'lib/Pod/Readme/Plugin/version.pm',
    'lib/Pod/Readme/Types.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/10-pod-readme-filter.t',
    't/20-pod-readme.t',
    't/author-clean-namespaces.t',
    't/author-critic.t',
    't/author-eof.t',
    't/author-eol.t',
    't/author-minimum-version.t',
    't/author-no-tabs.t',
    't/author-pod-syntax.t',
    't/author-portability.t',
    't/data/META-1.yml',
    't/data/README-1.pod',
    't/data/README.txt',
    't/lib/Pod/Readme/Plugin/noop.pm',
    't/lib/Pod/Readme/Test.pm',
    't/lib/Pod/Readme/Test/Kit.pm',
    't/plugins/changes.t',
    't/plugins/requires.t',
    't/plugins/version.t',
    't/release-check-manifest.t',
    't/release-fixme.t',
    't/release-kwalitee.t',
    't/release-trailing-space.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
