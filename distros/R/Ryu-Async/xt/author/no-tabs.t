use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Ryu/Async.pm',
    'lib/Ryu/Async.pod',
    'lib/Ryu/Async/Client.pm',
    'lib/Ryu/Async/Packet.pm',
    'lib/Ryu/Async/Process.pm',
    'lib/Ryu/Async/Process.pod',
    'lib/Ryu/Async/Server.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/sink.t',
    't/source.t',
    't/stream.t',
    't/tcp.t',
    't/timer.t',
    't/udp.t',
    'xt/author/distmeta.t',
    'xt/author/eol.t',
    'xt/author/minimum-version.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/author/test-version.t',
    'xt/release/common_spelling.t',
    'xt/release/cpan-changes.t'
);

notabs_ok($_) foreach @files;
done_testing;
