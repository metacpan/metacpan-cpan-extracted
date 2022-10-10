use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MooX/Tag/TO_HASH.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/class.t',
    't/lib/My/Test/C1.pm',
    't/lib/My/Test/C1_R1.pm',
    't/lib/My/Test/C2_C1.pm',
    't/lib/My/Test/C2_C1_R1.pm',
    't/lib/My/Test/C3.pm',
    't/lib/My/Test/C4.pm',
    't/lib/My/Test/R1.pm',
    't/modify.t',
    't/no_recurse.t',
    't/recurse.t',
    't/role.t',
    't/subclass.t',
    't/subclass_role.t'
);

notabs_ok($_) foreach @files;
done_testing;
