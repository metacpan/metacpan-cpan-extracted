use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MooX/PDL/Role/Proxy.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/clip.t',
    't/inplace_flag.t',
    't/inplace_flag.t.orig',
    't/lib/My/Class.pm',
    't/lib/My/Class/Nested.pm',
    't/lib/My/Class/Nested/NDarray.pm',
    't/lib/My/Class/Nested/Piddle.pm',
    't/lib/My/Class/Single.pm',
    't/lib/My/Class/Single/NDarray.pm',
    't/lib/My/Class/Single/Piddle.pm',
    't/lib/My/Test.pm',
    't/lib/My/Test/Role.pm',
    't/lib/My/Test/Role/Base.pm',
    't/lib/My/Test/Role/Nested.pm',
    't/lib/My/Test/Role/Nested/NDarray.pm',
    't/lib/My/Test/Role/Nested/Piddle.pm',
    't/lib/My/Test/Role/Single.pm',
    't/lib/My/Test/Role/Single/NDarray.pm',
    't/lib/My/Test/Role/Single/Piddle.pm',
    't/nested.t',
    't/qsort.t',
    't/slice.t',
    't/test.t'
);

notabs_ok($_) foreach @files;
done_testing;
