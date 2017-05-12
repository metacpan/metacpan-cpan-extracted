use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.14

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/POE/Component/Supervisor.pm',
    'lib/POE/Component/Supervisor/Handle.pm',
    'lib/POE/Component/Supervisor/Handle/Interface.pm',
    'lib/POE/Component/Supervisor/Handle/Proc.pm',
    'lib/POE/Component/Supervisor/Handle/Session.pm',
    'lib/POE/Component/Supervisor/Interface.pm',
    'lib/POE/Component/Supervisor/LogDispatch.pm',
    'lib/POE/Component/Supervisor/Supervised.pm',
    'lib/POE/Component/Supervisor/Supervised/Interface.pm',
    'lib/POE/Component/Supervisor/Supervised/Proc.pm',
    'lib/POE/Component/Supervisor/Supervised/Session.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01_load.t',
    't/02_basic.t',
    't/03_stubborn.t',
    't/04_global_restart_policy.t',
    't/05_sessions.t',
    'xt/author/00-compile.t',
    'xt/author/clean-namespaces.t',
    'xt/author/eol.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-spell.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/kwalitee.t',
    'xt/release/minimum-version.t',
    'xt/release/mojibake.t',
    'xt/release/pod-no404s.t',
    'xt/release/pod-syntax.t',
    'xt/release/portability.t'
);

notabs_ok($_) foreach @files;
done_testing;
