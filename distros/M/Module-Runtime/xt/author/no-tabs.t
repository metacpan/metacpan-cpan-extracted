use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Module/Runtime.pm',
    't/cmn.t',
    't/dependency.t',
    't/import_error.t',
    't/ivmn.t',
    't/ivms.t',
    't/lib/t/Break.pm',
    't/lib/t/Context.pm',
    't/lib/t/Eval.pm',
    't/lib/t/Hints.pm',
    't/lib/t/Nest0.pm',
    't/lib/t/Nest1.pm',
    't/lib/t/Simple.pm',
    't/mnf.t',
    't/rm.t',
    't/taint.t',
    't/um.t',
    't/upo.t',
    't/upo_overridden.t'
);

notabs_ok($_) foreach @files;
done_testing;
