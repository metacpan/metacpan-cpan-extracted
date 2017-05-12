use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MooseX/Singleton.pm',
    'lib/MooseX/Singleton/Role/Meta/Class.pm',
    'lib/MooseX/Singleton/Role/Meta/Instance.pm',
    'lib/MooseX/Singleton/Role/Meta/Method/Constructor.pm',
    'lib/MooseX/Singleton/Role/Object.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/001-basic.t',
    't/002-init.t',
    't/003-immutable.t',
    't/004-build_bug.t',
    't/005-build_bug-immutable.t',
    't/006-cooperative.t',
    't/warnings_once.t',
    't/zzz-check-breaks.t',
    'xt/author/00-compile.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-coverage.t',
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
