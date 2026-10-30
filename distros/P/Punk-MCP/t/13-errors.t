#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use PMCPRpc;

# The bytes Maat sends for the same faults (Maat/include/mt_mcp.h), so a client
# that talks to both sees the same framing.
my %MAAT = (
    parse   => '{"error":{"code":-32700,"message":"parse error"},"id":null,"jsonrpc":"2.0"}',
    invalid => '{"error":{"code":-32600,"message":"invalid request"},"id":null,"jsonrpc":"2.0"}',
    batch   => '{"error":{"code":-32600,"message":"batches are not supported"},"id":null,"jsonrpc":"2.0"}',
    method  => '{"error":{"code":-32601,"message":"method not found"},"id":7,"jsonrpc":"2.0"}',
);

my ($s, $b) = rpc_raw({}, '{oops');
is($b, $MAAT{parse}, '-32700 as Maat sends it');
is($s, 400, 'with 400');

($s, $b) = rpc_raw({}, '{"jsonrpc":"2.0","method":"ping","id":null}');
is($b, $MAAT{invalid}, '-32600 as Maat sends it, null id');
is($s, 400, 'with 400');

($s, $b) = rpc_raw({}, '[]');
is($b, $MAAT{batch}, 'the batch refusal as Maat sends it');

($s, $b) = rpc_raw({}, req(7, 'tools/frobnicate'));
is($b, $MAAT{method}, '-32601 as Maat sends it, with the id');
is($s, 200, 'with 200: the request was well formed');

# A bad jsonrpc with a usable id echoes the id, as Maat does.
($s, $b) = rpc_raw({}, '{"jsonrpc":"1.0","method":"ping","id":"x"}');
is($b, '{"error":{"code":-32600,"message":"invalid request"},"id":"x","jsonrpc":"2.0"}',
    '-32600 echoes a usable id');

# -32602
my $r;
($s, $r) = rpc({}, '{"jsonrpc":"2.0","id":5,"method":"initialize","params":"x"}');
is($r->{error}{code}, -32602, '-32602 for params that are not an object');
is($r->{error}{message}, 'params must be an object', 'saying so');
is($r->{id}, 5, 'with the id');

# A second initialize on a live session.
($s, $r) = rpc({ in_session => 1 }, req(6, 'initialize', { protocolVersion => '2025-11-25' }));
is($r->{error}{code}, -32600, 'a second initialize in a session is -32600');
is($r->{error}{message}, 'session already initialized', 'saying so');
is($r->{id}, 6, 'with the id');
is($s, 200, 'and 200, since the message itself was well formed');

($s, $r) = rpc({ in_session => 1 }, req(8, 'ping'));
is_deeply($r->{result}, {}, 'other requests in a session are served');

# -32603: a tool whose result cannot be encoded. Pinned in t/23-results.t.

done_testing;
