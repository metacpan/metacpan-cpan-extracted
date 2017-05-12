use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MooseX/UndefTolerant.pm',
    'lib/MooseX/UndefTolerant/ApplicationToClass.pm',
    'lib/MooseX/UndefTolerant/ApplicationToRole.pm',
    'lib/MooseX/UndefTolerant/Attribute.pm',
    'lib/MooseX/UndefTolerant/Class.pm',
    'lib/MooseX/UndefTolerant/Composite.pm',
    'lib/MooseX/UndefTolerant/Constructor.pm',
    'lib/MooseX/UndefTolerant/Role.pm',
    't/00-load.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t',
    't/constructor.t',
    't/defaults.t',
    't/lib/ConstructorTests.pm',
    't/roles.t',
    't/undef_init_arg.t',
    't/zzz-check-breaks.t',
    'xt/author/00-compile.t',
    'xt/author/clean-namespaces.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-no404s.t',
    'xt/author/pod-spell.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/minimum-version.t'
);

notabs_ok($_) foreach @files;
done_testing;
