use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MooseX/Util.pm',
    'lib/MooseX/Util/Meta/Class.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/000-report-versions-tiny.t',
    't/basic.t',
    't/find_meta.t',
    't/is_private.t',
    't/metaclass/compat.t',
    't/metaclass/validate.t',
    't/with_traits.t'
);

notabs_ok($_) foreach @files;
done_testing;
