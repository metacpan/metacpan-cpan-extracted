use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.08

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/package-stash-conflicts',
    'lib/Package/Stash.pm',
    'lib/Package/Stash/Conflicts.pm',
    'lib/Package/Stash/PP.pm',
    't/00-compile.t',
    't/addsub.t',
    't/anon-basic.t',
    't/anon.t',
    't/bare-anon-basic.t',
    't/bare-anon.t',
    't/basic.t',
    't/compile-time.t',
    't/edge-cases.t',
    't/extension.t',
    't/get.t',
    't/impl-selection/basic-pp.t',
    't/impl-selection/basic-xs.t',
    't/impl-selection/bug-rt-78272.t',
    't/impl-selection/choice.t',
    't/impl-selection/env.t',
    't/impl-selection/var.t',
    't/io.t',
    't/isa.t',
    't/lib/CompileTime.pm',
    't/lib/Package/Stash.pm',
    't/magic.t',
    't/paamayim_nekdotayim.t',
    't/scalar-values.t',
    't/stash-deletion.t',
    't/synopsis.t',
    't/warnings-taint.t',
    't/warnings.t'
);

notabs_ok($_) foreach @files;
done_testing;
