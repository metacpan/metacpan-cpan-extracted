use strict;
use warnings;
use utf8;

use Test2::V0;
use JSON::MaybeXS qw( encode_json decode_json );
use MIME::Base64 qw( encode_base64 );
use Encode      qw( encode );

use HTTP::Request::Common qw( POST GET PUT DELETE );
use Plack::Test();

use Net::Async::MCP::Server;
use Net::Async::MCP::Server::Transport::StreamableHTTP;

sub _decode_ok {
    my ($body) = @_;
    my $out = decode_json($body);
    ok( ref $out eq 'HASH', 'body decoded as hashref' );
    return $out;
}

sub _build_envelope {
    my (%over) = @_;
    my %base = (
        jsonrpc => '2.0',
        id      => 1,
        method  => 'server/discover',
        params  => {
            _meta => {
                'io.modelcontextprotocol/protocolVersion'    => '2026-07-28',
                'io.modelcontextprotocol/clientCapabilities' => {},
            },
        },
    );
    return { %base, %over };
}

sub _make_server {
    my $server = Net::Async::MCP::Server->new(name => 'http-test');
    $server->register_tool(
        name        => 'echo',
        description => 'Echoes msg',
        inputSchema => {
            type       => 'object',
            properties => {
                msg => { type => 'string', 'x-mcp-header' => 'Msg' },
            },
        },
        code => sub {
            my ($args) = @_;
            return { echoed => $args->{msg} };
        },
    );
    # A tool whose x-mcp-header parameters are non-string JSON types, so the
    # Mcp-Param-{Name} parity check has to compare a boolean / integer body
    # value against its lowercase / decimal-string header form.
    $server->register_tool(
        name        => 'typed',
        description => 'Echoes typed args',
        inputSchema => {
            type       => 'object',
            properties => {
                flag  => { type => 'boolean', 'x-mcp-header' => 'Flag' },
                count => { type => 'integer', 'x-mcp-header' => 'Count' },
            },
        },
        code => sub {
            my ($args) = @_;
            return { flag => $args->{flag}, count => $args->{count} };
        },
    );
    return $server;
}

sub _make_call_envelope {
    my (%over) = @_;
    my $base = _build_envelope(
        id     => 7,
        method => 'tools/call',
        params => {
            _meta => {
                'io.modelcontextprotocol/protocolVersion'    => '2026-07-28',
                'io.modelcontextprotocol/clientCapabilities' => {},
            },
            name      => 'echo',
            arguments => { msg => 'hello' },
        },
    );
    # Tunnel key-only overrides into params.arguments so the test can swap
    # the msg value without restating the whole envelope.
    if ( exists $over{arguments} ) {
        $base->{params}{arguments} = delete $over{arguments};
    }
    if ( exists $over{name} ) {
        $base->{params}{name} = delete $over{name};
    }
    return { %{ $base }, %over };
}

subtest 'POST application/json returns JSON-RPC response' => sub {
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $req = POST(
        '/mcp',
        'Content-Type'           => 'application/json',
        'Accept'                 => 'application/json',
        'MCP-Protocol-Version'   => '2026-07-28',
        'Mcp-Method'             => 'server/discover',
        'Content'                => encode_json(_build_envelope(id => 1)),
    );
    my $res = $test->request($req);

    is($res->code, 200, '200 OK');
    is($res->content_type, 'application/json', 'JSON content-type');

    my $body = _decode_ok($res->content);
    is($body->{jsonrpc}, '2.0', 'jsonrpc 2.0');
    is($body->{id}, 1, 'id matches');
    is($body->{result}{resultType}, 'complete', 'resultType complete');
};

subtest 'POST text/event-stream wraps response in SSE' => sub {
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $req = POST(
        '/mcp',
        'Content-Type'           => 'application/json',
        'Accept'                 => 'application/json, text/event-stream',
        'MCP-Protocol-Version'   => '2026-07-28',
        'Mcp-Method'             => 'server/discover',
        'Content'                => encode_json(_build_envelope(id => 42)),
    );
    my $res = $test->request($req);

    is($res->code, 200, '200 OK');
    is($res->content_type, 'text/event-stream', 'SSE content-type');

    my $body = $res->content;
    like($body, qr/^data: /m, 'body has data: prefix');
    like($body, qr/\n\n\z/, 'body ends with blank line');

    my ($data_line) = $body =~ m{^data: (.*)$}m;
    ok($data_line, 'captured data line');
    my $payload = _decode_ok($data_line);
    is($payload->{id}, 42, 'id in SSE payload');
    is($payload->{result}{resultType}, 'complete', 'resultType complete');
};

subtest 'Accept: text/event-stream on an erroring request downgrades to plain JSON' => sub {
    # SSE alone can't carry a JSON-RPC error in any spec-mandated way, so a
    # request that would normally stream falls back to application/json
    # once handle() answers with an error instead of a result.
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $envelope = _build_envelope(
        id     => 55,
        params => {
            _meta => {
                'io.modelcontextprotocol/protocolVersion'    => '1999-01-01',
                'io.modelcontextprotocol/clientCapabilities' => {},
            },
        },
    );

    my $req = POST(
        '/mcp',
        'Content-Type'           => 'application/json',
        'Accept'                 => 'application/json, text/event-stream',
        'MCP-Protocol-Version'   => '1999-01-01',
        'Mcp-Method'             => 'server/discover',
        'Content'                => encode_json($envelope),
    );
    my $res = $test->request($req);

    # An unsupported protocol version is one of the three spec-mandated
    # non-200 classes: the streamable-http spec maps it to 400 Bad Request
    # (UnsupportedProtocolVersionError). The SSE downgrade is orthogonal —
    # the body is still plain JSON, not an event stream.
    is($res->code, 400, '400 Bad Request (unsupported protocol version)');
    is($res->content_type, 'application/json', 'plain JSON, not SSE, despite Accept');

    my $body = _decode_ok($res->content);
    is($body->{error}{code}, -32022, 'JSON-RPC error -32022 Unsupported protocol version');
};

subtest 'notifications/initialized returns 202 with no body' => sub {
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $notification = {
        jsonrpc => '2.0',
        method  => 'notifications/initialized',
        params  => {},
    };
    my $req = POST(
        '/mcp',
        'Content-Type' => 'application/json',
        'Accept'       => 'application/json',
        'Content'      => encode_json($notification),
    );
    my $res = $test->request($req);

    is($res->code, 202, '202 Accepted');
    is($res->content, '', 'empty body');
};

subtest 'MCP-Protocol-Version mismatch returns 400 -32020' => sub {
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $envelope = _build_envelope(
        id     => 1,
        params => {
            _meta => {
                'io.modelcontextprotocol/protocolVersion'    => '2026-07-28',
                'io.modelcontextprotocol/clientCapabilities' => {},
            },
        },
    );
    $envelope->{params}{_meta}{'io.modelcontextprotocol/protocolVersion'} = '1999-01-01';

    my $req = POST(
        '/mcp',
        'Content-Type'         => 'application/json',
        'Accept'               => 'application/json',
        'MCP-Protocol-Version' => 'no-such-version',
        'Mcp-Method'           => 'server/discover',
        'Content'              => encode_json($envelope),
    );
    my $res = $test->request($req);

    is($res->code, 400, '400 Bad Request');
    my $body = _decode_ok($res->content);
    is($body->{error}{code}, -32020, 'JSON-RPC error -32020');
    like(
        $body->{error}{message},
        qr/MCP-Protocol-Version/,
        'message names the header',
    );
};

subtest 'Mcp-Method mismatch returns 400 -32020' => sub {
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $req = POST(
        '/mcp',
        'Content-Type'         => 'application/json',
        'Accept'               => 'application/json',
        'MCP-Protocol-Version' => '2026-07-28',
        'Mcp-Method'           => 'tools/call',
        'Content'              => encode_json(_build_envelope(id => 1)),
    );
    my $res = $test->request($req);

    is($res->code, 400, '400 Bad Request');
    my $body = _decode_ok($res->content);
    is($body->{error}{code}, -32020, 'JSON-RPC error -32020');
    like(
        $body->{error}{message},
        qr/Mcp-Method/,
        'message names the header',
    );
};

subtest 'Mcp-Name mismatch returns 400 -32020' => sub {
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $req = POST(
        '/mcp',
        'Content-Type'         => 'application/json',
        'Accept'               => 'application/json',
        'MCP-Protocol-Version' => '2026-07-28',
        'Mcp-Method'           => 'tools/call',
        'Mcp-Name'             => 'wrong_tool',
        'Content'              => encode_json(_make_call_envelope(id => 5)),
    );
    my $res = $test->request($req);

    is($res->code, 400, '400 Bad Request');
    my $body = _decode_ok($res->content);
    is($body->{error}{code}, -32020, 'JSON-RPC error -32020');
    like(
        $body->{error}{message},
        qr/Mcp-Name/,
        'message names the header',
    );
};

subtest 'Origin not in allowlist returns 403' => sub {
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server              => $server,
        origin_allow        => ['https://trusted.example.com'],
    );
    my $test = Plack::Test->create( $t->to_app );

    my $req = POST(
        '/mcp',
        'Content-Type'         => 'application/json',
        'Accept'               => 'application/json',
        'Origin'               => 'https://evil.example.com',
        'MCP-Protocol-Version' => '2026-07-28',
        'Mcp-Method'           => 'server/discover',
        'Content'              => encode_json(_build_envelope(id => 99)),
    );
    my $res = $test->request($req);

    is($res->code, 403, '403 Forbidden');
    my $body = _decode_ok($res->content);
    is($body->{id}, undef, 'id is null in JSON-RPC envelope');
    ok(exists $body->{error}, 'error field present');
    is($body->{error}{code}, -32600, 'JSON-RPC error code -32600');
    like(
        $body->{error}{message},
        qr/Origin/i,
        'message mentions Origin',
    );
};

subtest 'Origin in allowlist passes' => sub {
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server              => $server,
        origin_allow        => ['https://trusted.example.com'],
    );
    my $test = Plack::Test->create( $t->to_app );

    my $req = POST(
        '/mcp',
        'Content-Type'         => 'application/json',
        'Accept'               => 'application/json',
        'Origin'               => 'https://trusted.example.com',
        'MCP-Protocol-Version' => '2026-07-28',
        'Mcp-Method'           => 'server/discover',
        'Content'              => encode_json(_build_envelope(id => 1)),
    );
    my $res = $test->request($req);

    is($res->code, 200, '200 OK on allowed origin');
};

subtest 'origin_allow configured but no Origin header sent passes' => sub {
    # A deliberate non-browser passthrough: the Origin header only exists
    # because browsers send it. A client that omits it entirely (curl, a
    # server-to-server caller) is not subject to the allowlist check.
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server              => $server,
        origin_allow        => ['https://trusted.example.com'],
    );
    my $test = Plack::Test->create( $t->to_app );

    my $req = POST(
        '/mcp',
        'Content-Type'         => 'application/json',
        'Accept'               => 'application/json',
        'MCP-Protocol-Version' => '2026-07-28',
        'Mcp-Method'           => 'server/discover',
        'Content'              => encode_json(_build_envelope(id => 1)),
    );
    my $res = $test->request($req);

    is($res->code, 200, '200 OK with no Origin header, despite allowlist');
};

subtest 'empty origin_allow permits any origin' => sub {
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $req = POST(
        '/mcp',
        'Content-Type'         => 'application/json',
        'Accept'               => 'application/json',
        'Origin'               => 'https://anywhere.example.com',
        'MCP-Protocol-Version' => '2026-07-28',
        'Mcp-Method'           => 'server/discover',
        'Content'              => encode_json(_build_envelope(id => 1)),
    );
    my $res = $test->request($req);

    is($res->code, 200, '200 OK with empty allowlist');
};

subtest 'x-mcp-header parity passes when header matches body' => sub {
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $req = POST(
        '/mcp',
        'Content-Type'         => 'application/json',
        'Accept'               => 'application/json',
        'MCP-Protocol-Version' => '2026-07-28',
        'Mcp-Method'           => 'tools/call',
        'Mcp-Name'             => 'echo',
        'Mcp-Param-Msg'        => 'hello',
        'Content'              => encode_json(
            _make_call_envelope(id => 6, arguments => { msg => 'hello' }),
        ),
    );
    my $res = $test->request($req);

    is($res->code, 200, '200 OK on matching header');
    my $body = _decode_ok($res->content);
    is($body->{result}{content}[0]{text}, '{"echoed":"hello"}', 'tool returned echoed value');
};

subtest 'x-mcp-header mismatch returns 400 -32020' => sub {
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $req = POST(
        '/mcp',
        'Content-Type'         => 'application/json',
        'Accept'               => 'application/json',
        'MCP-Protocol-Version' => '2026-07-28',
        'Mcp-Method'           => 'tools/call',
        'Mcp-Name'             => 'echo',
        'Mcp-Param-Msg'        => 'wrong_value',
        'Content'              => encode_json(
            _make_call_envelope(id => 8, arguments => { msg => 'correct_value' }),
        ),
    );
    my $res = $test->request($req);

    is($res->code, 400, '400 Bad Request');
    my $body = _decode_ok($res->content);
    is($body->{error}{code}, -32020, 'JSON-RPC error -32020');
    like(
        $body->{error}{message},
        qr/Mcp-Param/i,
        'message names the param header',
    );
};

subtest 'x-mcp-header parity with base64 UTF-8 value matches body' => sub {
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $utf8_value = 'Hellö Wörld';
    my $b64 = encode_base64(encode('UTF-8', $utf8_value), '');

    my $req = POST(
        '/mcp',
        'Content-Type'         => 'application/json',
        'Accept'               => 'application/json',
        'MCP-Protocol-Version' => '2026-07-28',
        'Mcp-Method'           => 'tools/call',
        'Mcp-Name'             => 'echo',
        'Mcp-Param-Msg'        => "=?base64?$b64?=",
        'Content'              => encode_json(
            _make_call_envelope(id => 9, arguments => { msg => $utf8_value }),
        ),
    );
    my $res = $test->request($req);

    is($res->code, 200, '200 OK on base64 UTF-8 match');
    my $body = _decode_ok($res->content);

    # The tool's return value is JSON-encoded into the text content block.
    # The exact byte form depends on the JSON encoder's UTF-8 handling, so
    # compare the inner JSON value rather than the textual representation.
    my $payload = decode_json( $body->{result}{content}[0]{text} );
    is(
        $payload->{echoed} . '',
        $utf8_value . '',
        'tool echoed decoded UTF-8 value',
    );
};

subtest 'x-mcp-header argument not in body returns 400 -32020' => sub {
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $req = POST(
        '/mcp',
        'Content-Type'         => 'application/json',
        'Accept'               => 'application/json',
        'MCP-Protocol-Version' => '2026-07-28',
        'Mcp-Method'           => 'tools/call',
        'Mcp-Name'             => 'echo',
        'Mcp-Param-Msg'        => 'something',
        'Content'              => encode_json(
            _make_call_envelope(id => 10, arguments => {}),
        ),
    );
    my $res = $test->request($req);

    is($res->code, 400, '400 Bad Request when header refers to absent argument');
    my $body = _decode_ok($res->content);
    is($body->{error}{code}, -32020, 'JSON-RPC error -32020');
};

subtest 'GET on /mcp returns 405' => sub {
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $req = GET('/mcp');
    my $res = $test->request($req);

    is($res->code, 405, '405 Method Not Allowed');
    is($res->header('Allow'), 'POST', 'Allow: POST');
};

subtest 'DELETE on /mcp returns 405' => sub {
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $req = DELETE('/mcp');
    my $res = $test->request($req);

    is($res->code, 405, '405 Method Not Allowed');
    is($res->header('Allow'), 'POST', 'Allow: POST');
};

subtest 'PUT on /mcp returns 405' => sub {
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $req = PUT('/mcp', 'Content-Type' => 'application/json', 'Content' => '{}');
    my $res = $test->request($req);

    is($res->code, 405, '405 Method Not Allowed');
    is($res->header('Allow'), 'POST', 'Allow: POST');
};

subtest 'POST with wrong Content-Type returns -32700' => sub {
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $req = POST(
        '/mcp',
        'Content-Type' => 'text/plain',
        'Content'      => 'not json',
    );
    my $res = $test->request($req);

    is($res->code, 400, '400 Bad Request');
    my $body = _decode_ok($res->content);
    is($body->{error}{code}, -32700, 'JSON-RPC error -32700 Parse error');
    like(
        $body->{error}{message},
        qr/Content-Type/i,
        'message explains the Content-Type requirement',
    );
};

subtest 'POST with invalid JSON body returns -32700' => sub {
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $req = POST(
        '/mcp',
        'Content-Type' => 'application/json',
        'Content'      => '{not valid json',
    );
    my $res = $test->request($req);

    is($res->code, 400, '400 Bad Request');
    my $body = _decode_ok($res->content);
    is($body->{error}{code}, -32700, 'JSON-RPC error -32700');
};

subtest 'POST to unknown path returns 404' => sub {
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $req = POST('/other',
        'Content-Type' => 'application/json',
        'Content'      => '{}',
    );
    my $res = $test->request($req);

    is($res->code, 404, '404 Not Found');
};

subtest 'subscriptions/listen returns 404 -32601 Method not found' => sub {
    # subscriptions/listen was removed: there is no server->client push
    # channel to deliver it in this version, so it falls through handle()'s
    # normal dispatch and comes back as a plain JSON-RPC -32601, the same
    # answer any other unknown method gets — not an SSE acknowledgement. Per
    # the streamable-http spec an unimplemented RPC method is 404 Not Found,
    # which is how clients tell a modern server from a legacy one.
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $envelope = _build_envelope(
        id     => 'sub-1',
        method => 'subscriptions/listen',
        params => {
            _meta => {
                'io.modelcontextprotocol/protocolVersion'    => '2026-07-28',
                'io.modelcontextprotocol/clientCapabilities' => {},
            },
            notifications => {
                'tools/list_changed' => {},
            },
        },
    );

    my $req = POST(
        '/mcp',
        'Content-Type'         => 'application/json',
        'Accept'               => 'application/json',
        'MCP-Protocol-Version' => '2026-07-28',
        'Mcp-Method'           => 'subscriptions/listen',
        'Content'              => encode_json($envelope),
    );
    my $res = $test->request($req);

    is($res->code, 404, '404 Not Found (unimplemented RPC method)');
    is($res->content_type, 'application/json', 'plain JSON, not SSE');

    my $body = _decode_ok($res->content);
    is($body->{id}, 'sub-1', 'id echoed back');
    ok(exists $body->{error}, 'error field present');
    is($body->{error}{code}, -32601, 'JSON-RPC error -32601 Method not found');
};

subtest 'configure defaults are loopback + 8080 + /mcp' => sub {
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new;
    is($t->host, '127.0.0.1', 'default host loopback');
    is($t->port, 8080, 'default port 8080');
    is($t->path, '/mcp', 'default path /mcp');
    is(scalar @{ $t->origin_allow }, 0, 'empty origin_allow');
};

subtest 'non-loopback host warns (does not error)' => sub {
    # The warn lives in listen(), not in the constructor, so this must
    # actually call listen() to exercise the warn logic — but listen() also
    # binds a real socket via HTTP::Server::PSGI and blocks in ->run, which
    # the hard "no network, no spawned process" rule forbids. Locally mock
    # HTTP::Server::PSGI's new/run so listen() runs its warn logic and
    # returns without ever touching a socket.
    require HTTP::Server::PSGI;
    local *HTTP::Server::PSGI::new = sub { bless {}, 'HTTP::Server::PSGI' };
    local *HTTP::Server::PSGI::run = sub { return };

    my $server = _make_server;
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, shift };
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
        host               => '0.0.0.0',
    );
    $t->listen;

    is(scalar @warn, 1, 'exactly one warning');
    like($warn[0], qr/non-loopback/, 'warning mentions non-loopback');
};

subtest 'loopback host (127.0.0.1) does not warn' => sub {
    require HTTP::Server::PSGI;
    local *HTTP::Server::PSGI::new = sub { bless {}, 'HTTP::Server::PSGI' };
    local *HTTP::Server::PSGI::run = sub { return };

    my $server = _make_server;
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, shift };
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
        host               => '127.0.0.1',
    );
    $t->listen;

    is(scalar @warn, 0, 'no warning for loopback host');
};

subtest 'allow_external_bind silences the non-loopback warning' => sub {
    require HTTP::Server::PSGI;
    local *HTTP::Server::PSGI::new = sub { bless {}, 'HTTP::Server::PSGI' };
    local *HTTP::Server::PSGI::run = sub { return };

    my $server = _make_server;
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, shift };
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
        host               => '0.0.0.0',
    );
    $t->listen( allow_external_bind => 1 );

    is(scalar @warn, 0, 'no warning when allow_external_bind is set');
};

subtest 'x-mcp-header argument lookup is case-insensitive' => sub {
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    # Mcp-Param-Msg header references the lowercased `msg` argument. The
    # CGIs env folds the header suffix to uppercase, but the lookup is
    # case-insensitive on the body side.
    my $req = POST(
        '/mcp',
        'Content-Type'         => 'application/json',
        'Accept'               => 'application/json',
        'MCP-Protocol-Version' => '2026-07-28',
        'Mcp-Method'           => 'tools/call',
        'Mcp-Name'             => 'echo',
        'Mcp-Param-Msg'        => 'hello',
        'Content'              => encode_json(
            _make_call_envelope(id => 11, arguments => { msg => 'hello' }),
        ),
    );
    my $res = $test->request($req);

    is($res->code, 200, '200 OK on case-insensitive lookup');
};

subtest 'Mcp-Param boolean true matches lowercase true header' => sub {
    # Regression: a JSON true in the body stringifies to "1" in Perl, but the
    # spec (and the sibling client) carries it as the word 'true'. A raw eq
    # compared "1" against "true" and answered a bogus -32020.
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $req = POST(
        '/mcp',
        'Content-Type'         => 'application/json',
        'Accept'               => 'application/json',
        'MCP-Protocol-Version' => '2026-07-28',
        'Mcp-Method'           => 'tools/call',
        'Mcp-Name'             => 'typed',
        'Mcp-Param-Flag'       => 'true',
        'Content'              => encode_json(
            _make_call_envelope(
                id        => 20,
                name      => 'typed',
                arguments => { flag => JSON::MaybeXS::true() },
            ),
        ),
    );
    my $res = $test->request($req);

    is($res->code, 200, '200 OK: boolean true matches header true');
};

subtest 'Mcp-Param boolean false matches lowercase false header' => sub {
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $req = POST(
        '/mcp',
        'Content-Type'         => 'application/json',
        'Accept'               => 'application/json',
        'MCP-Protocol-Version' => '2026-07-28',
        'Mcp-Method'           => 'tools/call',
        'Mcp-Name'             => 'typed',
        'Mcp-Param-Flag'       => 'false',
        'Content'              => encode_json(
            _make_call_envelope(
                id        => 21,
                name      => 'typed',
                arguments => { flag => JSON::MaybeXS::false() },
            ),
        ),
    );
    my $res = $test->request($req);

    is($res->code, 200, '200 OK: boolean false matches header false');
};

subtest 'Mcp-Param boolean true against numeric 1 header returns 400 -32020' => sub {
    # The Perl truth value of a JSON boolean is not its wire form: '1' is not
    # the spec-mandated 'true', so the parity check must reject it.
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $req = POST(
        '/mcp',
        'Content-Type'         => 'application/json',
        'Accept'               => 'application/json',
        'MCP-Protocol-Version' => '2026-07-28',
        'Mcp-Method'           => 'tools/call',
        'Mcp-Name'             => 'typed',
        'Mcp-Param-Flag'       => '1',
        'Content'              => encode_json(
            _make_call_envelope(
                id        => 22,
                name      => 'typed',
                arguments => { flag => JSON::MaybeXS::true() },
            ),
        ),
    );
    my $res = $test->request($req);

    is($res->code, 400, '400 Bad Request: boolean true does not match header 1');
    my $body = _decode_ok($res->content);
    is($body->{error}{code}, -32020, 'JSON-RPC error -32020');
};

subtest 'Mcp-Param integer compares numerically (42 matches 42.0 header)' => sub {
    # Regression: a JSON integer 42 stringifies to "42"; a spec-conformant but
    # non-canonical header "42.0" must still be accepted, because integers are
    # compared numerically, not as strings.
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $req = POST(
        '/mcp',
        'Content-Type'         => 'application/json',
        'Accept'               => 'application/json',
        'MCP-Protocol-Version' => '2026-07-28',
        'Mcp-Method'           => 'tools/call',
        'Mcp-Name'             => 'typed',
        'Mcp-Param-Count'      => '42.0',
        'Content'              => encode_json(
            _make_call_envelope(
                id        => 23,
                name      => 'typed',
                arguments => { count => 42 },
            ),
        ),
    );
    my $res = $test->request($req);

    is($res->code, 200, '200 OK: 42.0 header matches integer 42 numerically');
};

subtest 'Mcp-Param integer against non-numeric header returns 400 -32020' => sub {
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $req = POST(
        '/mcp',
        'Content-Type'         => 'application/json',
        'Accept'               => 'application/json',
        'MCP-Protocol-Version' => '2026-07-28',
        'Mcp-Method'           => 'tools/call',
        'Mcp-Name'             => 'typed',
        'Mcp-Param-Count'      => 'abc',
        'Content'              => encode_json(
            _make_call_envelope(
                id        => 24,
                name      => 'typed',
                arguments => { count => 42 },
            ),
        ),
    );
    my $res = $test->request($req);

    is($res->code, 400, '400 Bad Request: non-numeric header cannot match integer 42');
    my $body = _decode_ok($res->content);
    is($body->{error}{code}, -32020, 'JSON-RPC error -32020');
};

subtest 'Mcp-Param numeric-looking string body: declared string compares as string' => sub {
    # The echo tool declares msg as type string, so the schema-aware check
    # (k39) compares "42" against the header as a string: "42.0" is a
    # mismatch. Integer-declared params keep numeric leniency (see the typed
    # tool tests).
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $req = POST(
        '/mcp',
        'Content-Type'         => 'application/json',
        'Accept'               => 'application/json',
        'MCP-Protocol-Version' => '2026-07-28',
        'Mcp-Method'           => 'tools/call',
        'Mcp-Name'             => 'echo',
        'Mcp-Param-Msg'        => '42.0',
        'Content'              => encode_json(
            _make_call_envelope(
                id        => 25,
                name      => 'echo',
                arguments => { msg => '42' },
            ),
        ),
    );
    my $res = $test->request($req);

    is($res->code, 400, '400: declared string "42" does not match header 42.0');
};

subtest 'missing clientCapabilities in body _meta returns 400 -32602' => sub {
    # The 2026-07-28 spec requires io.modelcontextprotocol/clientCapabilities
    # in params._meta on every request. A request missing a required field is
    # malformed; the streamable-http transport MUST reject it with 400 and
    # -32602 (Invalid params), rather than passing it to handle() and
    # returning the body-only 200 that an unknown-tool -32602 gets.
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $envelope = _build_envelope(
        id     => 30,
        params => {
            _meta => {
                'io.modelcontextprotocol/protocolVersion' => '2026-07-28',
            },
        },
    );

    my $req = POST(
        '/mcp',
        'Content-Type'         => 'application/json',
        'Accept'               => 'application/json',
        'MCP-Protocol-Version' => '2026-07-28',
        'Mcp-Method'           => 'server/discover',
        'Content'              => encode_json($envelope),
    );
    my $res = $test->request($req);

    is($res->code, 400, '400 Bad Request');
    my $body = _decode_ok($res->content);
    is($body->{error}{code}, -32602, 'JSON-RPC error -32602 Invalid params');
    like(
        $body->{error}{message},
        qr/clientCapabilities/,
        'message names the missing field',
    );
};

subtest 'tools/call on an unregistered tool stays 200 -32602' => sub {
    # An unknown tool is a parameter error (-32602), not one of the three
    # spec-mandated non-200 classes, so it stays HTTP 200 with the error in
    # the body. This is the counterpart to the missing-clientCapabilities
    # case above: both are -32602, but only a missing required _meta field is
    # 400 — a -32602 that survives to handle() is genuinely an application
    # error and keeps its 200.
    my $server = _make_server;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $req = POST(
        '/mcp',
        'Content-Type'         => 'application/json',
        'Accept'               => 'application/json',
        'MCP-Protocol-Version' => '2026-07-28',
        'Mcp-Method'           => 'tools/call',
        'Mcp-Name'             => 'no_such_tool',
        'Content'              => encode_json(
            _make_call_envelope(id => 31, name => 'no_such_tool', arguments => {}),
        ),
    );
    my $res = $test->request($req);

    is($res->code, 200, '200 OK (JSON-RPC error in body, not an HTTP error)');
    my $body = _decode_ok($res->content);
    is($body->{error}{code}, -32602, 'JSON-RPC error -32602 unknown tool');
};

subtest 'resources/read internal error (-32603) stays 200' => sub {
    # -32603 (Internal error) is not one of the spec's three non-200 classes,
    # so a resource whose read dies comes back HTTP 200 with the error in the
    # body — the generic-error case the status mapping must leave untouched.
    my $server = _make_server;
    $server->register_resource(
        uri  => 'file:///boom',
        name => 'boom',
        # No code ref: read_resource dies with "has no implementation", which
        # handle() maps to -32603.
    );
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
        server             => $server,
    );
    my $test = Plack::Test->create( $t->to_app );

    my $envelope = _build_envelope(
        id     => 32,
        method => 'resources/read',
        params => {
            _meta => {
                'io.modelcontextprotocol/protocolVersion'    => '2026-07-28',
                'io.modelcontextprotocol/clientCapabilities' => {},
            },
            uri => 'file:///boom',
        },
    );

    my $req = POST(
        '/mcp',
        'Content-Type'         => 'application/json',
        'Accept'               => 'application/json',
        'MCP-Protocol-Version' => '2026-07-28',
        'Mcp-Method'           => 'resources/read',
        'Mcp-Name'             => 'file:///boom',
        'Content'              => encode_json($envelope),
    );
    my $res = $test->request($req);

    is($res->code, 200, '200 OK (internal error in body, not an HTTP error)');
    my $body = _decode_ok($res->content);
    is($body->{error}{code}, -32603, 'JSON-RPC error -32603 Internal error');
};

# --- k39: x-mcp-header enforced from the registered inputSchema -----------

sub _schema_server {
    my $server = Net::Async::MCP::Server->new(name => 'schema-test');
    my $code = sub { return { ok => 1 } };
    $server->register_tool(
        name => 'nested', description => 'n', code => $code,
        inputSchema => {
            type       => 'object',
            properties => {
                a => {
                    type       => 'object',
                    properties => {
                        b => { type => 'string', 'x-mcp-header' => 'Deep' },
                    },
                },
            },
        },
    );
    $server->register_tool(
        name => 'hidden', description => 'h', code => $code,
        inputSchema => {
            type       => 'object',
            properties => {
                list => {
                    type  => 'array',
                    items => { type => 'object', properties => {
                        x => { type => 'string', 'x-mcp-header' => 'InItems' },
                    } },
                },
                alt => {
                    oneOf => [ { type => 'object', properties => {
                        y => { type => 'string', 'x-mcp-header' => 'InOneOf' },
                    } } ],
                },
            },
        },
    );
    $server->register_tool(
        name => 'str', description => 's', code => $code,
        inputSchema => {
            type       => 'object',
            properties => {
                code => { type => 'string', 'x-mcp-header' => 'Code' },
                num  => { type => 'integer', 'x-mcp-header' => 'Num' },
            },
        },
    );
    return $server;
}

sub _call {
    my ( $server, $tool, $args, %headers ) = @_;
    my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new( server => $server );
    my $test = Plack::Test->create( $t->to_app );
    my $res = $test->request( POST(
        '/mcp',
        'Content-Type'         => 'application/json',
        'Accept'               => 'application/json',
        'MCP-Protocol-Version' => '2026-07-28',
        'Mcp-Method'           => 'tools/call',
        'Mcp-Name'             => $tool,
        %headers,
        'Content' => encode_json(
            _make_call_envelope( id => 9, name => $tool, arguments => $args ),
        ),
    ) );
    return ( $res, scalar decode_json( $res->content ) );
}

subtest 'k39: annotated value in body but header missing is rejected' => sub {
    my ( $res, $body ) = _call( _make_server, 'echo', { msg => 'hello' } );
    is( $res->code, 400, '400' );
    is( $body->{error}{code}, -32020, '-32020' );
    like( $body->{error}{message}, qr/Mcp-Param-Msg header is required/, 'message' );
};

subtest 'k39: annotated value with matching header passes' => sub {
    my ( $res ) = _call( _make_server, 'echo', { msg => 'hello' }, 'Mcp-Param-Msg' => 'hello' );
    is( $res->code, 200, '200' );
};

subtest 'k39: null value or absent argument needs no header' => sub {
    my ( $res ) = _call( _make_server, 'echo', { msg => undef } );
    is( $res->code, 200, 'null value: 200' );
    ( $res ) = _call( _make_server, 'echo', {} );
    is( $res->code, 200, 'absent argument: 200' );
};

subtest 'k39: nested properties annotation expects its header' => sub {
    my $s = _schema_server;
    my ( $res, $body ) = _call( $s, 'nested', { a => { b => 'x' } } );
    is( $res->code, 400, '400 without header' );
    like( $body->{error}{message}, qr/Mcp-Param-Deep header is required/, 'message' );
    ( $res ) = _call( $s, 'nested', { a => { b => 'x' } }, 'Mcp-Param-Deep' => 'x' );
    is( $res->code, 200, '200 with header' );
};

subtest 'k39: annotations under items / oneOf are ignored' => sub {
    my ( $res ) = _call( _schema_server, 'hidden', {
        list => [ { x => 'v' } ],
        alt  => { y => 'v' },
    } );
    is( $res->code, 200, '200 without any header' );
};

subtest 'k39: declared string compares as string, integer stays numeric' => sub {
    my $s = _schema_server;
    my ( $res, $body ) = _call( $s, 'str', { code => '42' }, 'Mcp-Param-Code' => '42.0' );
    is( $res->code, 400, 'string "42" vs header 42.0 mismatches' );
    is( $body->{error}{code}, -32020, '-32020' );
    ( $res ) = _call( $s, 'str', { num => 42 }, 'Mcp-Param-Num' => '42.0' );
    is( $res->code, 200, 'integer 42 vs 42.0 still matches' );
};

subtest 'k39: unknown tool is not schema-checked' => sub {
    my ( $res, $body ) = _call( _make_server, 'nope', { msg => 'x' } );
    is( $body->{error}{code}, -32602, 'handle() -32602' );
    unlike( $body->{error}{message}, qr/header is required/, 'no header complaint' );
};

subtest 'k39: find_tool accessor' => sub {
    my $s = _make_server;
    is( $s->find_tool('echo')->{name}, 'echo', 'found' );
    ok( !$s->find_tool('nope'), 'unknown returns false' );
};


subtest 'Mcp-Param header with null or missing body value is -32020 without warnings' => sub {
    # Regression: an undef body value reached `eq` in _header_value_matches
    # and warned "uninitialized value $body_value in string eq". The outcome
    # (header present, body value null/missing => mismatch) is unchanged.
    my @cases = (
        [ 'JSON null, undeclared param' => 'echo',  'Msg',  { msg => undef } ],
        [ 'missing, undeclared param'   => 'echo',  'Msg',  { other => 1 } ],
        [ 'JSON null, x-mcp-header'     => 'typed', 'Flag', { flag => undef } ],
        [ 'missing, x-mcp-header'       => 'typed', 'Flag', {} ],
    );
    my $id = 40;
    for my $case (@cases) {
        my ( $label, $tool, $hdr, $args ) = @$case;
        my $server = _make_server;
        my $t = Net::Async::MCP::Server::Transport::StreamableHTTP->new(
            server => $server,
        );
        my $test = Plack::Test->create( $t->to_app );
        my $req = POST(
            '/mcp',
            'Content-Type'         => 'application/json',
            'Accept'               => 'application/json',
            'MCP-Protocol-Version' => '2026-07-28',
            'Mcp-Method'           => 'tools/call',
            'Mcp-Name'             => $tool,
            "Mcp-Param-$hdr"       => 'something',
            'Content'              => encode_json(
                _make_call_envelope(
                    id => $id++, name => $tool, arguments => $args,
                ),
            ),
        );
        my $res;
        my $warnings = warnings { $res = $test->request($req) };
        is($res->code, 400, "$label: 400");
        is(_decode_ok($res->content)->{error}{code}, -32020, "$label: -32020");
        is($warnings, [], "$label: no warnings");
    }
};

done_testing;
