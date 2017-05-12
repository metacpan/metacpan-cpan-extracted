use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MooseX/ClassAttribute.pm',
    'lib/MooseX/ClassAttribute/Meta/Role/Attribute.pm',
    'lib/MooseX/ClassAttribute/Trait/Application.pm',
    'lib/MooseX/ClassAttribute/Trait/Application/ToClass.pm',
    'lib/MooseX/ClassAttribute/Trait/Application/ToRole.pm',
    'lib/MooseX/ClassAttribute/Trait/Attribute.pm',
    'lib/MooseX/ClassAttribute/Trait/Class.pm',
    'lib/MooseX/ClassAttribute/Trait/Mixin/HasClassAttributes.pm',
    'lib/MooseX/ClassAttribute/Trait/Role.pm',
    'lib/MooseX/ClassAttribute/Trait/Role/Composite.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/02-immutable.t',
    't/03-introspection.t',
    't/04-with-native-traits.t',
    't/05-with-attribute-helpers-backcompat.t',
    't/06-role.t',
    't/07-parameterized-role.t',
    't/08-role-composition.t',
    't/09-bare-native-traits.t',
    't/10-strict-role-composition.t',
    't/11-moose-exporter.t',
    't/12-with-initializer.t',
    't/lib/SharedTests.pm'
);

notabs_ok($_) foreach @files;
done_testing;
