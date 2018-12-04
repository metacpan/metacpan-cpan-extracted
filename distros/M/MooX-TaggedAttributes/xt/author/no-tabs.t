use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MooX/TaggedAttributes.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/cache.t',
    't/class_role_inherited.t',
    't/late_role_to_object.t',
    't/lib/My/Test.pm',
    't/lib/R1.pm',
    't/lib/R2.pm',
    't/lib/R3.pm',
    't/lib/T1.pm',
    't/lib/T12.pm',
    't/lib/T2.pm'
);

notabs_ok($_) foreach @files;
done_testing;
