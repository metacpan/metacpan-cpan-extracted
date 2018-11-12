use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MooX/Attributes/Shadow.pm',
    'lib/MooX/Attributes/Shadow/Role.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/class_vs_object.t',
    't/conted_public_attr.t',
    't/conter_alias.t',
    't/conter_alias_hash.t',
    't/conter_instance.t',
    't/conter_private_attr.t',
    't/conter_public_attr.t',
    't/err_attrs.t',
    't/lib/Contained.pm',
    't/lib/ContainedWRole.pm',
    't/lib/Container1.pm',
    't/lib/Container2.pm',
    't/lib/Container3.pm',
    't/new_from_attrs.t',
    't/not-moo.t'
);

notabs_ok($_) foreach @files;
done_testing;
