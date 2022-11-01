use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MooX/Tag/TO_HASH.pm',
    'lib/MooX/Tag/TO_HASH/Util.pm',
    'lib/MooX/Tag/TO_JSON.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/lib/My/Test/TO_HASH/C1.pm',
    't/lib/My/Test/TO_HASH/C1_R1.pm',
    't/lib/My/Test/TO_HASH/C2_C1.pm',
    't/lib/My/Test/TO_HASH/C2_C1_R1.pm',
    't/lib/My/Test/TO_HASH/C3.pm',
    't/lib/My/Test/TO_HASH/C4.pm',
    't/lib/My/Test/TO_HASH/C4_deprecated.pm',
    't/lib/My/Test/TO_HASH/R1.pm',
    't/lib/My/Test/TO_JSON/C1.pm',
    't/lib/My/Test/TO_JSON/C1_R1.pm',
    't/lib/My/Test/TO_JSON/C2_C1.pm',
    't/lib/My/Test/TO_JSON/C2_C1_R1.pm',
    't/lib/My/Test/TO_JSON/C3.pm',
    't/lib/My/Test/TO_JSON/C4.pm',
    't/lib/My/Test/TO_JSON/C4_deprecated.pm',
    't/lib/My/Test/TO_JSON/R1.pm',
    't/parent_modifiers.t',
    't/to_hash/class.t',
    't/to_hash/modify.t',
    't/to_hash/modify_deprecated.t',
    't/to_hash/no_recurse.t',
    't/to_hash/recurse.t',
    't/to_hash/role.t',
    't/to_hash/subclass.t',
    't/to_hash/subclass_role.t',
    't/to_json/class.t',
    't/to_json/modify.t',
    't/to_json/modify_deprecated.t',
    't/to_json/no_recurse.t',
    't/to_json/role.t',
    't/to_json/subclass.t',
    't/to_json/subclass_role.t'
);

notabs_ok($_) foreach @files;
done_testing;
