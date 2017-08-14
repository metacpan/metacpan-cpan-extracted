use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MooseX/RelatedClasses.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/all_in_namespace.t',
    't/basic.t',
    't/blank_namespace.t',
    't/custom-decamelization.t',
    't/desnaking-with-doublecolon.t',
    't/lib/Test/Class/__WONKY__.pm',
    't/lib/Test/Class/__WONKY__/One.pm',
    't/lib/Test/Class/__WONKY__/Sub/One.pm',
    't/multiple.t',
    't/sugar.t'
);

notabs_ok($_) foreach @files;
done_testing;
