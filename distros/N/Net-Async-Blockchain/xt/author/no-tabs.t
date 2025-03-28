use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Net/Async/Blockchain.pm',
    'lib/Net/Async/Blockchain.pod',
    'lib/Net/Async/Blockchain/BTC.pm',
    'lib/Net/Async/Blockchain/BTC.pod',
    'lib/Net/Async/Blockchain/Client/RPC.pm',
    'lib/Net/Async/Blockchain/Client/RPC.pod',
    'lib/Net/Async/Blockchain/Client/RPC/BTC.pm',
    'lib/Net/Async/Blockchain/Client/RPC/BTC.pod',
    'lib/Net/Async/Blockchain/Client/RPC/ETH.pm',
    'lib/Net/Async/Blockchain/Client/RPC/ETH.pod',
    'lib/Net/Async/Blockchain/Client/RPC/Omni.pm',
    'lib/Net/Async/Blockchain/Client/RPC/Omni.pod',
    'lib/Net/Async/Blockchain/Client/Websocket.pm',
    'lib/Net/Async/Blockchain/Client/Websocket.pod',
    'lib/Net/Async/Blockchain/Client/ZMQ.pm',
    'lib/Net/Async/Blockchain/Client/ZMQ.pod',
    'lib/Net/Async/Blockchain/ETH.pm',
    'lib/Net/Async/Blockchain/ETH.pod',
    'lib/Net/Async/Blockchain/TRX.pm',
    'lib/Net/Async/Blockchain/TRX.pod',
    'lib/Net/Async/Blockchain/Transaction.pm',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/btc.t',
    't/eth.t',
    't/rc/perlcriticrc',
    't/rc/perltidyrc',
    't/rpc.t',
    't/websocket.t',
    't/zmq.t',
    'xt/author/critic.t',
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
