use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'examples/moose_room.pl',
    'lib/MooseX/Daemonize.pm',
    'lib/MooseX/Daemonize/Core.pm',
    'lib/MooseX/Daemonize/Pid.pm',
    'lib/MooseX/Daemonize/Pid/File.pm',
    'lib/MooseX/Daemonize/WithPidFile.pm',
    'lib/Test/MooseX/Daemonize.pm',
    't/00-load.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-filecreate.t',
    't/02-stdout.t',
    't/10-pidfile.t',
    't/20-core.t',
    't/21-core-back-compat.t',
    't/30-with-pid-file.t',
    't/zzz-check-breaks.t',
    'xt/author/00-compile.t',
    'xt/author/clean-namespaces.t',
    'xt/author/eol.t',
    'xt/author/kwalitee.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-coverage.t',
    'xt/author/pod-syntax.t',
    'xt/release/changes_has_content.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/minimum-version.t',
    'xt/release/portability.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
