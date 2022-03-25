use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MooX/TaggedAttributes.pm',
    'lib/MooX/TaggedAttributes/Cache.pm',
    'lib/MooX/TaggedAttributes/Role.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/cache.t',
    't/class_role_inherited.t',
    't/extra_handler.t',
    't/late_role_to_object.t',
    't/lib/B1.pm',
    't/lib/B2.pm',
    't/lib/B3.pm',
    't/lib/B4.pm',
    't/lib/C1.pm',
    't/lib/C10.pm',
    't/lib/C2.pm',
    't/lib/C3.pm',
    't/lib/C31.pm',
    't/lib/C4.pm',
    't/lib/C5.pm',
    't/lib/C6.pm',
    't/lib/C7.pm',
    't/lib/C8.pm',
    't/lib/C9.pm',
    't/lib/My/Handler/C1.pm',
    't/lib/My/Handler/C12.pm',
    't/lib/My/Handler/C1_2.pm',
    't/lib/My/Handler/C2.pm',
    't/lib/My/Handler/CC1.pm',
    't/lib/My/Handler/CC1_2.pm',
    't/lib/My/Handler/R0.pm',
    't/lib/My/Handler/T1.pm',
    't/lib/My/Handler/T12.pm',
    't/lib/My/Handler/T2.pm',
    't/lib/My/Test.pm',
    't/lib/R1.pm',
    't/lib/R1.pm.orig',
    't/lib/R2.pm',
    't/lib/R3.pm',
    't/lib/T1.pm',
    't/lib/T12.pm',
    't/lib/T2.pm',
    't/namespace.t'
);

notabs_ok($_) foreach @files;
done_testing;
