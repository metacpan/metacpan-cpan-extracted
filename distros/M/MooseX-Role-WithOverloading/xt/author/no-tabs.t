use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MooseX/Role/WithOverloading.pm',
    'lib/MooseX/Role/WithOverloading/Meta/Role.pm',
    'lib/MooseX/Role/WithOverloading/Meta/Role/Application.pm',
    'lib/MooseX/Role/WithOverloading/Meta/Role/Application/Composite.pm',
    'lib/MooseX/Role/WithOverloading/Meta/Role/Application/Composite/ToClass.pm',
    'lib/MooseX/Role/WithOverloading/Meta/Role/Application/Composite/ToInstance.pm',
    'lib/MooseX/Role/WithOverloading/Meta/Role/Application/Composite/ToRole.pm',
    'lib/MooseX/Role/WithOverloading/Meta/Role/Application/FixOverloadedRefs.pm',
    'lib/MooseX/Role/WithOverloading/Meta/Role/Application/ToClass.pm',
    'lib/MooseX/Role/WithOverloading/Meta/Role/Application/ToInstance.pm',
    'lib/MooseX/Role/WithOverloading/Meta/Role/Application/ToRole.pm',
    'lib/MooseX/Role/WithOverloading/Meta/Role/Composite.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/combine_to_class.t',
    't/combine_to_instance.t',
    't/combine_to_role.t',
    't/core_moose.t',
    't/lib/ClassWithCombiningRole.pm',
    't/lib/CombiningClass.pm',
    't/lib/CombiningRole.pm',
    't/lib/OtherClass.pm',
    't/lib/OtherRole.pm',
    't/lib/Role.pm',
    't/lib/SomeClass.pm',
    't/lib/UnrelatedRole.pm',
    't/remove_attributes_bug.t',
    't/to_class.t',
    't/to_instance.t',
    't/to_role.t',
    't/zzz-check-breaks.t',
    'xt/author/00-compile.t',
    'xt/author/clean-namespaces.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-spell.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/minimum-version.t',
    'xt/release/pod-coverage.t',
    'xt/release/pod-no404s.t',
    'xt/release/pod-syntax.t',
    'xt/release/portability.t'
);

notabs_ok($_) foreach @files;
done_testing;
