use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.11

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MooseX/Object/Pluggable.pm',
    't/00-load.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/02-basic2.t',
    't/03-custom-ns.t',
    't/04-reload.t',
    't/05-load-failure.t',
    't/lib/CustomNS/Plugin/Foo.pm',
    't/lib/TestApp.pm',
    't/lib/TestApp/Plugin/Bar.pm',
    't/lib/TestApp/Plugin/Baz.pm',
    't/lib/TestApp/Plugin/Bor.pm',
    't/lib/TestApp/Plugin/Foo.pm',
    't/lib/TestApp2.pm',
    't/lib/TestApp2/Plugin/Foo.pm',
    't/lib/TestApp3.pm',
    't/lib/TestApp3/Plugin/Dies1.pm',
    't/lib/TestApp3/Plugin/Dies2.pm',
    't/lib/TestApp3/Plugin/Lives.pm',
    't/zzz-check-breaks.t',
    'xt/author/00-compile.t',
    'xt/author/eol.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-spell.t',
    'xt/release/changes_has_content.t',
    'xt/release/clean-namespaces.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/kwalitee.t',
    'xt/release/minimum-version.t',
    'xt/release/mojibake.t',
    'xt/release/pod-coverage.t',
    'xt/release/pod-no404s.t',
    'xt/release/pod-syntax.t',
    'xt/release/portability.t'
);

notabs_ok($_) foreach @files;
done_testing;
