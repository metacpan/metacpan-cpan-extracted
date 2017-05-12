use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Pod/Weaver/Role/Section/Formattable.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/000-report-versions-tiny.t',
    't/basic.t',
    't/basic/in.pod',
    't/basic/out.pod',
    't/basic/weaver.ini',
    't/funcs.pm',
    't/lib/Pod/Weaver/Section/Test/Formatter.pm',
    't/lib/Pod/Weaver/Section/Test/Formatter2.pm',
    't/multi/in.pod',
    't/multi/out.pod',
    't/multi/weaver.ini',
    't/section/source/in.pod',
    't/section/source/out.pod',
    't/section/source/weaver.ini'
);

notabs_ok($_) foreach @files;
done_testing;
