use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MooseX/TrackDirty/Attributes.pm',
    'lib/MooseX/TrackDirty/Attributes/Trait/Attribute.pm',
    'lib/MooseX/TrackDirty/Attributes/Trait/Attribute/Native/Trait.pm',
    'lib/MooseX/TrackDirty/Attributes/Trait/Class.pm',
    'lib/MooseX/TrackDirty/Attributes/Trait/Method/Accessor.pm',
    'lib/MooseX/TrackDirty/Attributes/Trait/Method/Accessor/Native.pm',
    'lib/MooseX/TrackDirty/Attributes/Trait/Role.pm',
    'lib/MooseX/TrackDirty/Attributes/Trait/Role/Application/ToClass.pm',
    'lib/MooseX/TrackDirty/Attributes/Trait/Role/Application/ToInstance.pm',
    'lib/MooseX/TrackDirty/Attributes/Trait/Role/Application/ToRole.pm',
    'lib/MooseX/TrackDirty/Attributes/Trait/Role/Composite.pm',
    'lib/MooseX/TrackDirty/Attributes/Util.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/000-report-versions-tiny.t',
    't/01-moose.t',
    't/02-basic.t',
    't/extends.t',
    't/funcs.pm',
    't/native-traits/basic.t',
    't/native-traits/extends/basic.t',
    't/native-traits/extends/in-same-class.t',
    't/native-traits/extends/reversed-in-same-class.t',
    't/native-traits/extends/reversed.t',
    't/native-traits/role.t',
    't/native-traits/to-instance.t',
    't/native-traits/trait-combined.t'
);

notabs_ok($_) foreach @files;
done_testing;
