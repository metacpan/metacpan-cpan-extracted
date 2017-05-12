use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.13

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Reindeer.pm',
    'lib/Reindeer/Builder.pm',
    'lib/Reindeer/Role.pm',
    'lib/Reindeer/Types.pm',
    'lib/Reindeer/Util.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/000-report-versions-tiny.t',
    't/basic_load.t',
    't/builder/basic.t',
    't/feature.t',
    't/imports.t',
    't/moosex-abstract/basic.t',
    't/moosex-currieddelegation/basic.t',
    't/moosex-markasmethods/basic.t',
    't/moosex-newdefaults/basic.t',
    't/moosex-strictconstructor/basic.t',
    't/moosex-traitor/basic.t',
    't/optional-traits/autodestruct.t',
    't/optional-traits/env.t',
    't/optional-traits/undeftolerant.t',
    't/types.t'
);

notabs_ok($_) foreach @files;
done_testing;
