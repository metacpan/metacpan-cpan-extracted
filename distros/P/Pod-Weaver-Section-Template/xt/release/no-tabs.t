use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::NoTabsTests 0.08

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Pod/Weaver/Section/Template.pm',
    't/00-compile.t',
    't/01-basic.t',
    't/01/template.section',
    't/01/weaver.ini',
    't/02-dzil.t',
    't/02/bugs.section',
    't/02/dist.ini',
    't/02/lib/Foo/Bar.pm',
    't/02/lib/Foo/Baz.pm',
    't/02/support.section',
    't/02/weaver.ini'
);

notabs_ok($_) foreach @files;
done_testing;
