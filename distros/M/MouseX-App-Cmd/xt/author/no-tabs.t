use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.09

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/MouseX/App/Cmd.pm',
    'lib/MouseX/App/Cmd/Command.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/basic.t',
    't/build_emulates_new.t',
    't/configfile.t',
    't/lib/Test/ConfigFromFile.pm',
    't/lib/Test/ConfigFromFile/Command/boo.pm',
    't/lib/Test/ConfigFromFile/Command/moo.pm',
    't/lib/Test/ConfigFromFile/config.yaml',
    't/lib/Test/MyAny/Mouse.pm',
    't/lib/Test/MyAny/Mouse/Command/foo.pm',
    't/lib/Test/MyCmd.pm',
    't/lib/Test/MyCmd/Command/bark.pm',
    't/lib/Test/MyCmd/Command/frobulate.pm',
    't/lib/Test/MyCmd/Command/justusage.pm',
    't/lib/Test/MyCmd/Command/stock.pm',
    't/moose.t',
    'xt/author/00-compile.t',
    'xt/author/clean-namespaces.t',
    'xt/author/critic.t',
    'xt/author/eol.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-spell.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/kwalitee.t',
    'xt/release/minimum-version.t',
    'xt/release/mojibake.t',
    'xt/release/pod-coverage.t',
    'xt/release/pod-no404s.t',
    'xt/release/pod-syntax.t',
    'xt/release/portability.t',
    'xt/release/synopsis.t'
);

notabs_ok($_) foreach @files;
done_testing;
