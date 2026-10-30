#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use PMCPRpc;

my $PARSE = '{"error":{"code":-32700,"message":"parse error"},"id":null,"jsonrpc":"2.0"}';

# ---- bytes that are not JSON ---------------------------------------------------

# Run inside a loop on purpose: a croak trapped the wrong way answers correctly
# here and then breaks the loop that called it ("panic: pp_iter").
my @bad = (
    [ 'truncated',          '{"jsonrpc":"2.0","id":1,"method":' ],
    [ 'trailing content',   '{"jsonrpc":"2.0","id":1,"method":"ping"} x' ],
    [ 'empty body',         '' ],
    [ 'whitespace only',    "  \n" ],
    [ 'a bare word',        'nul' ],
    [ 'invalid UTF-8',      qq({"jsonrpc":"2.0","id":1,"method":"\xff"}) ],
    [ 'a lone surrogate',   '{"jsonrpc":"2.0","id":1,"method":"\ud800"}' ],
    [ 'deep nesting',       ('[' x 600) . (']' x 600) ],
);
my $loops = 0;
for my $case (@bad) {
    my ($name, $bytes) = @$case;
    my ($status, $reply) = rpc_raw({}, $bytes);
    is($status, 400, "$name: 400");
    is($reply, $PARSE, "$name: -32700 with a null id");
    $loops++;
}
is($loops, scalar @bad, 'and the loop around them ran to the end');

my ($s, $r) = rpc({}, req(1, 'ping'));
is($r->{id}, 1, 'the interpreter is whole after all of them');

# ---- JSON that is not JSON-RPC --------------------------------------------------

($s, $r) = rpc({}, '[' . req(1, 'ping') . ']');
is($s, 400, 'a batch is 400');
is($r->{error}{code}, -32600, 'a batch is -32600');
is($r->{error}{message}, 'batches are not supported', 'and says why');
($s, $r) = rpc({}, '[]');
is($r->{error}{message}, 'batches are not supported', 'an empty batch too');

for my $case (
    [ 'a scalar document',  '1' ],
    [ 'a string document',  '"ping"' ],
    [ 'no jsonrpc',         '{"id":1,"method":"ping"}' ],
    [ 'jsonrpc 1.0',        '{"jsonrpc":"1.0","id":1,"method":"ping"}' ],
    [ 'jsonrpc as a number','{"jsonrpc":2.0,"id":1,"method":"ping"}' ],
    [ 'method a number',    '{"jsonrpc":"2.0","id":1,"method":7}' ],
    [ 'method an object',   '{"jsonrpc":"2.0","id":1,"method":{}}' ],
    [ 'neither method nor result', '{"jsonrpc":"2.0","id":1}' ],
) {
    my ($name, $bytes) = @$case;
    ($s, $r) = rpc({}, $bytes);
    is($s, 400, "$name: 400");
    is($r->{error}{code}, -32600, "$name: -32600");
}

# ---- ids of every JSON type ---------------------------------------------------------

# Echoed exactly: 1 stays a number and "1" stays a string, read from the bytes.
for my $case (
    [ '1',                      '"id":1,'                    ],
    [ '"1"',                    '"id":"1",'                  ],
    [ '-5',                     '"id":-5,'                   ],
    [ '0',                      '"id":0,'                    ],
    [ '12345678901234567890',   '"id":12345678901234567890,' ],
    [ '""',                     '"id":"",'                   ],
    [ '"abc-é"',           qq("id":"abc-\xc3\xa9",)      ],
) {
    my ($id, $want) = @$case;
    my ($st, $bytes) = rpc_raw({}, qq({"jsonrpc":"2.0","id":$id,"method":"ping"}));
    is($st, 200, "id $id: answered");
    ok(index($bytes, $want) >= 0, "id $id: echoed as $want")
        or diag($bytes);
}

for my $id ('1.5', '1e3', 'true', 'false', 'null', '{}', '[]') {
    ($s, $r) = rpc({}, qq({"jsonrpc":"2.0","id":$id,"method":"ping"}));
    is($s, 400, "id $id: 400");
    is($r->{error}{code}, -32600, "id $id: -32600");
    ok(exists $r->{id} && !defined $r->{id}, "id $id: answered with a null id");
}

# ---- params ------------------------------------------------------------------------

($s, $r) = rpc({}, '{"jsonrpc":"2.0","id":3,"method":"ping","params":[1]}');
is($r->{error}{code}, -32602, 'params as an array is -32602');
is($r->{id}, 3, 'with the id');
($s, $r) = rpc({}, '{"jsonrpc":"2.0","id":3,"method":"ping","params":null}');
is_deeply($r->{result}, {}, 'params null is read as absent');
($s, $r) = rpc({}, '{"jsonrpc":"2.0","method":"ping","params":"x"}');
is($s, 202, 'a notification with bad params is still owed nothing');
ok(!defined $r, 'and gets no body');

# ---- the encoding ------------------------------------------------------------------

my ($st, $bytes) = rpc_raw({}, req(9, 'ping'));
is($bytes, '{"id":9,"jsonrpc":"2.0","result":{}}',
    'canonical: keys sorted, no whitespace');

done_testing;
