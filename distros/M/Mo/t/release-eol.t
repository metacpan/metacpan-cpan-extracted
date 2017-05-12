
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::EOLTests 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/mo-inline',
    'lib/Mo.pm',
    'lib/Mo.pod',
    'lib/Mo/Design.pod',
    'lib/Mo/Features.pod',
    'lib/Mo/Golf.pm',
    'lib/Mo/Hacking.pod',
    'lib/Mo/Inline.pm',
    'lib/Mo/Moose.pm',
    'lib/Mo/Moose.pod',
    'lib/Mo/Mouse.pm',
    'lib/Mo/Mouse.pod',
    'lib/Mo/build.pm',
    'lib/Mo/build.pod',
    'lib/Mo/builder.pm',
    'lib/Mo/builder.pod',
    'lib/Mo/chain.pm',
    'lib/Mo/chain.pod',
    'lib/Mo/coerce.pm',
    'lib/Mo/coerce.pod',
    'lib/Mo/default.pm',
    'lib/Mo/default.pod',
    'lib/Mo/exporter.pm',
    'lib/Mo/exports.pod',
    'lib/Mo/import.pm',
    'lib/Mo/import.pod',
    'lib/Mo/importer.pm',
    'lib/Mo/importer.pod',
    'lib/Mo/is.pm',
    'lib/Mo/is.pod',
    'lib/Mo/nonlazy.pm',
    'lib/Mo/option.pm',
    'lib/Mo/option.pod',
    'lib/Mo/required.pm',
    'lib/Mo/required.pod',
    'lib/Mo/xs.pm',
    'lib/Mo/xs.pod',
    't/000-report-versions-tiny.t',
    't/Bar.pm',
    't/Boo.pm',
    't/Foo.pm',
    't/Moose.t',
    't/Mouse.t',
    't/author-00-compile.t',
    't/author-pod-spell.t',
    't/author-pod-syntax.t',
    't/author-test-version.t',
    't/build.t',
    't/builder.t',
    't/chain.t',
    't/coerce.t',
    't/combined.t',
    't/default.t',
    't/extends.t',
    't/importer.t',
    't/is.t',
    't/lazy-nonlazy.t',
    't/main_sub.t',
    't/object.t',
    't/option.t',
    't/release-correct-version.t',
    't/release-distmeta.t',
    't/release-eol.t',
    't/release-no-tabs.t',
    't/required.t',
    't/strict.t',
    't/test.t',
    't/xs.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
