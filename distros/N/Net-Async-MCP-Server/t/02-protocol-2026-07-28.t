use strict;
use warnings;

use Test2::V0;
use Net::Async::MCP::Server;
use JSON::MaybeXS qw( encode_json );
use Future;

# Helper: build a fully-formed 2026-07-28 request envelope. Tests can override
# any field by passing args.
# Helper: the standard 2026-07-28 params envelope with the required _meta
# block. Pass extra params (name, arguments) to merge them alongside _meta.
sub _params {
    my (%extra) = @_;
    return {
        _meta => {
            'io.modelcontextprotocol/protocolVersion'    => '2026-07-28',
            'io.modelcontextprotocol/clientCapabilities' => {},
        },
        %extra,
    };
}

sub _req {
    my (%override) = @_;
    my %base = (
        jsonrpc => '2.0',
        id      => 1,
        method  => 'server/discover',
        params  => _params(),
    );
    return { %base, %override };
}

subtest 'server/discover' => sub {
    my $server = Net::Async::MCP::Server->new(name => 'disc-server');

    my $response = $server->handle(_req(method => 'server/discover', id => 7));

    ok($response, 'got response');
    is($response->{id}, 7, 'response id matches');
    is($response->{jsonrpc}, '2.0', 'jsonrpc 2.0');

    my $r = $response->{result};
    is($r->{resultType}, 'complete', 'resultType complete');
    is($r->{supportedVersions}[0], '2026-07-28', 'supportedVersions[0]');
    ok(exists $r->{capabilities}, 'capabilities present');

    # Per-result _meta must carry serverInfo.
    is(
        $r->{_meta}{'io.modelcontextprotocol/serverInfo'}{name},
        'disc-server',
        'serverInfo.name in _meta',
    );
    ok(
        defined $r->{_meta}{'io.modelcontextprotocol/serverInfo'}{version},
        'serverInfo.version in _meta',
    );

    # Caching hints per the spec MUST be present on complete cacheable results.
    ok(defined $r->{ttlMs}, 'ttlMs present');
    ok($r->{ttlMs} >= 0, 'ttlMs is non-negative');
    is($r->{cacheScope}, 'public', 'cacheScope public');
};

subtest 'tools/list result shape' => sub {
    my $server = Net::Async::MCP::Server->new;
    $server->register_tool(
        name         => 'my_tool',
        description  => 'A tool',
        inputSchema  => { type => 'object' },
    );

    my $response = $server->handle(_req(method => 'tools/list', id => 2));

    ok($response, 'got response');
    my $r = $response->{result};
    is($r->{resultType}, 'complete', 'resultType complete');
    is(scalar @{$r->{tools}}, 1, 'one tool in tools[]');
    is($r->{tools}[0]{name}, 'my_tool', 'tool name');
    ok(exists $r->{tools}[0]{inputSchema}, 'tool has inputSchema');
    ok(!exists $r->{tools}[0]{input_schema}, 'tool has no snake_case input_schema');
    ok(defined $r->{ttlMs}, 'ttlMs present');
    is($r->{cacheScope}, 'public', 'cacheScope public');
    ok(
        exists $r->{_meta}{'io.modelcontextprotocol/serverInfo'},
        '_meta.serverInfo present',
    );
};

subtest 'tools/call wraps plain return in text content block' => sub {
    my $server = Net::Async::MCP::Server->new;
    $server->register_tool(
        name         => 'echo',
        description  => 'Echoes input',
        inputSchema  => { type => 'object' },
        code         => sub {
            my ($args) = @_;
            return { echoed => $args->{value} };
        },
    );

    my $response = $server->handle(_req(
        id     => 3,
        method => 'tools/call',
        params => _params(
            name      => 'echo',
            arguments => { value => 'hello' },
        ),
    ));

    ok($response, 'got response');
    is($response->{id}, 3, 'response id matches');

    my $r = $response->{result};
    is($r->{resultType}, 'complete', 'resultType complete');
    ok(ref $r->{content} eq 'ARRAY', 'content is arrayref');
    is($r->{content}[0]{type}, 'text', 'first content is text');
    like(
        $r->{content}[0]{text},
        qr/echoed/,
        'text content carries the tool return value',
    );
};

subtest 'tools/call tool error becomes isError result, not JSON-RPC error' => sub {
    my $server = Net::Async::MCP::Server->new;
    $server->register_tool(
        name         => 'boom',
        description  => 'Always throws',
        inputSchema  => { type => 'object' },
        code         => sub { die "boom!\n" },
    );

    my $response = $server->handle(_req(
        id     => 4,
        method => 'tools/call',
        params => _params(
            name      => 'boom',
            arguments => {},
        ),
    ));

    ok($response, 'got response');
    ok(!exists $response->{error}, 'no JSON-RPC error');
    my $r = $response->{result};
    is($r->{resultType}, 'complete', 'resultType complete');
    ok($r->{isError}, 'isError true');
    is($r->{content}[0]{type}, 'text', 'content is text');
    like($r->{content}[0]{text}, qr/boom/, 'error message in content text');
};

subtest 'tools/call unknown tool returns -32602' => sub {
    my $server = Net::Async::MCP::Server->new;

    my $response = $server->handle(_req(
        id     => 5,
        method => 'tools/call',
        params => _params(
            name      => 'does_not_exist',
            arguments => {},
        ),
    ));

    ok($response, 'got response');
    ok(exists $response->{error}, 'JSON-RPC error returned');
    is($response->{error}{code}, -32602, 'error code -32602 Invalid params');
    like(
        $response->{error}{message},
        qr/unknown tool/i,
        'message mentions unknown tool',
    );
};

subtest 'MRTR input_required passes through unchanged' => sub {
    my $server = Net::Async::MCP::Server->new;
    $server->register_tool(
        name         => 'needs_input',
        description  => 'Needs more info',
        inputSchema  => { type => 'object' },
        code         => sub {
            return {
                resultType    => 'input_required',
                inputRequests => {
                    github_login => {
                        method => 'elicitation/create',
                        params => {
                            message         => 'Please provide your GitHub username',
                            requestedSchema => {
                                type       => 'object',
                                properties => { name => { type => 'string' } },
                                required   => ['name'],
                            },
                        },
                    },
                },
                requestState => 'opaque-blob',
            };
        },
    );

    my $response = $server->handle(_req(
        id     => 6,
        method => 'tools/call',
        params => _params(
            name      => 'needs_input',
            arguments => {},
        ),
    ));

    ok($response, 'got response');
    my $r = $response->{result};
    is($r->{resultType}, 'input_required', 'resultType input_required');
    ok(exists $r->{inputRequests}, 'inputRequests present');
    ok(exists $r->{inputRequests}{github_login}, 'inputRequests.github_login present');
    is(
        $r->{inputRequests}{github_login}{method},
        'elicitation/create',
        'elicitation/create method',
    );
    is($r->{requestState}, 'opaque-blob', 'requestState preserved');

    # Even MRTR results carry _meta.serverInfo — every successful result
    # does, per the spec.
    ok(
        exists $r->{_meta}{'io.modelcontextprotocol/serverInfo'},
        '_meta.serverInfo injected on MRTR result',
    );
};

subtest 'every successful result carries _meta.serverInfo' => sub {
    my $server = Net::Async::MCP::Server->new(name => 'meta-server');

    for my $method (qw(server/discover tools/list)) {
        my $response = $server->handle(_req(method => $method, id => 100));

        ok($response, "got response for $method");
        my $r = $response->{result};
        is(
            $r->{_meta}{'io.modelcontextprotocol/serverInfo'}{name},
            'meta-server',
            "serverInfo.name injected for $method",
        );
    }
};

subtest '_meta validation - missing protocolVersion returns -32602' => sub {
    my $server = Net::Async::MCP::Server->new;

    my $response = $server->handle({
        jsonrpc => '2.0',
        id      => 10,
        method  => 'server/discover',
        params  => {
            _meta => {
                'io.modelcontextprotocol/clientCapabilities' => {},
            },
        },
    });

    ok($response, 'got response');
    is($response->{error}{code}, -32602, 'error code -32602');
    like(
        $response->{error}{message},
        qr/protocolVersion/i,
        'message mentions protocolVersion',
    );
};

subtest '_meta validation - missing clientCapabilities returns -32602' => sub {
    my $server = Net::Async::MCP::Server->new;

    my $response = $server->handle({
        jsonrpc => '2.0',
        id      => 11,
        method  => 'server/discover',
        params  => {
            _meta => {
                'io.modelcontextprotocol/protocolVersion' => '2026-07-28',
            },
        },
    });

    ok($response, 'got response');
    is($response->{error}{code}, -32602, 'error code -32602');
    like(
        $response->{error}{message},
        qr/clientCapabilities/i,
        'message mentions clientCapabilities',
    );
};

subtest '_meta validation - missing _meta entirely returns -32602' => sub {
    my $server = Net::Async::MCP::Server->new;

    my $response = $server->handle({
        jsonrpc => '2.0',
        id      => 12,
        method  => 'server/discover',
        params  => {},
    });

    ok($response, 'got response');
    is($response->{error}{code}, -32602, 'error code -32602');
};

subtest 'unsupported protocol version returns -32022 with supported list' => sub {
    my $server = Net::Async::MCP::Server->new;

    my $response = $server->handle({
        jsonrpc => '2.0',
        id      => 13,
        method  => 'server/discover',
        params  => {
            _meta => {
                'io.modelcontextprotocol/protocolVersion'    => '1999-01-01',
                'io.modelcontextprotocol/clientCapabilities' => {},
            },
        },
    });

    ok($response, 'got response');
    is($response->{error}{code}, -32022, 'error code -32022');
    is(
        $response->{error}{message},
        'Unsupported protocol version',
        'message text',
    );
    ok(ref $response->{error}{data}{supported} eq 'ARRAY', 'data.supported arrayref');
    is(
        $response->{error}{data}{supported}[0],
        '2026-07-28',
        'data.supported[0]',
    );
    is(
        $response->{error}{data}{requested},
        '1999-01-01',
        'data.requested',
    );
};

subtest 'legacy 2025-11-25 version returns -32022' => sub {
    my $server = Net::Async::MCP::Server->new;

    my $response = $server->handle({
        jsonrpc => '2.0',
        id      => 14,
        method  => 'server/discover',
        params  => {
            _meta => {
                'io.modelcontextprotocol/protocolVersion'    => '2025-11-25',
                'io.modelcontextprotocol/clientCapabilities' => {},
            },
        },
    });

    is($response->{error}{code}, -32022, 'legacy version rejected with -32022');
};

subtest 'initialize is rejected with -32601' => sub {
    my $server = Net::Async::MCP::Server->new;

    my $response = $server->handle(_req(id => 20, method => 'initialize'));

    ok($response, 'got response');
    is($response->{error}{code}, -32601, 'error code -32601 Method not found');
    like(
        $response->{error}{message},
        qr/initialize/,
        'message mentions initialize',
    );
};

subtest 'ping is rejected with -32601' => sub {
    my $server = Net::Async::MCP::Server->new;

    my $response = $server->handle(_req(id => 21, method => 'ping'));

    ok($response, 'got response');
    is($response->{error}{code}, -32601, 'error code -32601 Method not found');
};

subtest 'notifications/initialized is a no-op' => sub {
    my $server = Net::Async::MCP::Server->new;

    my $response = $server->handle({
        jsonrpc => '2.0',
        method  => 'notifications/initialized',
        params  => {},
    });

    is($response, undef, 'notification returns undef (no response on wire)');
};

subtest 'notifications/tools/list_changed is a no-op' => sub {
    my $server = Net::Async::MCP::Server->new;

    my $response = $server->handle({
        jsonrpc => '2.0',
        method  => 'notifications/tools/list_changed',
    });

    is($response, undef, 'notification returns undef');
};

subtest 'unknown method returns -32601' => sub {
    my $server = Net::Async::MCP::Server->new;

    my $response = $server->handle(_req(id => 30, method => 'unknown/method'));

    is($response->{error}{code}, -32601, 'error code -32601');
};

subtest 'missing method returns -32600' => sub {
    my $server = Net::Async::MCP::Server->new;

    my $response = $server->handle({
        jsonrpc => '2.0',
        id      => 31,
    });

    is($response->{error}{code}, -32600, 'error code -32600');
};

subtest 'non-hash request returns -32700' => sub {
    my $server = Net::Async::MCP::Server->new;

    my $response = $server->handle('not a hash');

    ok($response, 'got response');
    is($response->{error}{code}, -32700, 'error code -32700 Parse error');
};

subtest 'call_tool gets full arguments ref and additional context-free path' => sub {
    my $server = Net::Async::MCP::Server->new;
    $server->register_tool(
        name         => 'arith',
        description  => 'Sum',
        inputSchema  => { type => 'object' },
        code         => sub {
            my ($args) = @_;
            return $args->{a} + $args->{b};
        },
    );

    my $response = $server->handle(_req(
        id     => 40,
        method => 'tools/call',
        params => _params(
            name      => 'arith',
            arguments => { a => 2, b => 3 },
        ),
    ));

    my $r = $response->{result};
    is($r->{content}[0]{text}, '5', 'plain return stringified into text content');
};

subtest 'notifications/initialized sent WITH an id returns -32601' => sub {
    # notifications/initialized is a legacy handshake method name. Sent as a
    # true notification (no id) it is a silent no-op (see the subtest above);
    # sent WITH an id it is a normal request, and normal requests get the
    # same -32601 Method not found any other unrecognised method gets.
    my $server = Net::Async::MCP::Server->new;

    my $response = $server->handle(_req(id => 50, method => 'notifications/initialized'));

    ok($response, 'got response');
    is($response->{error}{code}, -32601, 'error code -32601 Method not found');
};

subtest 'clientCapabilities present but undef (JSON null) still passes' => sub {
    # _validate_request_meta only checks `exists` on this key, never
    # `defined` — a client legitimately sending JSON null for
    # clientCapabilities must still dispatch. Pin this so a well-meaning
    # exists->defined "fix" would break it and be caught here.
    my $server = Net::Async::MCP::Server->new;

    my $response = $server->handle({
        jsonrpc => '2.0',
        id      => 51,
        method  => 'server/discover',
        params  => {
            _meta => {
                'io.modelcontextprotocol/protocolVersion'    => '2026-07-28',
                'io.modelcontextprotocol/clientCapabilities' => undef,
            },
        },
    });

    ok($response, 'got response');
    ok(!exists $response->{error}, 'no JSON-RPC error');
    ok(exists $response->{result}, 'result present');
    is($response->{result}{resultType}, 'complete', 'resultType complete');
};

subtest 'id == 0 and id == "" count as defined, not a notification' => sub {
    for my $id (0, '') {
        my $server = Net::Async::MCP::Server->new;
        my $response = $server->handle(_req(method => 'server/discover', id => $id));

        ok(defined $response, "id " . ( length("$id") ? "'$id'" : "''" ) . " gets a real response, not undef");
        is($response->{jsonrpc}, '2.0', 'jsonrpc 2.0');
        is($response->{id}, $id, 'response id echoes the request id exactly');
        ok(exists $response->{result}, 'result present (dispatched, not treated as a notification)');
    }
};

subtest 'tool registered with no code -> isError with has no implementation' => sub {
    my $server = Net::Async::MCP::Server->new;
    $server->register_tool(
        name        => 'no_code',
        description => 'Registered without a code ref',
        inputSchema => { type => 'object' },
    );

    my $response = $server->handle(_req(
        id     => 52,
        method => 'tools/call',
        params => _params(
            name      => 'no_code',
            arguments => {},
        ),
    ));

    ok($response, 'got response');
    ok(!exists $response->{error}, 'no JSON-RPC error (routed as a tool failure)');
    my $r = $response->{result};
    is($r->{resultType}, 'complete', 'resultType complete');
    ok($r->{isError}, 'isError true');
    like(
        $r->{content}[0]{text},
        qr/has no implementation/,
        'content text explains the tool has no implementation',
    );
};

subtest '_meta.serverInfo present on tools/call success and isError results' => sub {
    my $server = Net::Async::MCP::Server->new(name => 'call-meta-server');
    $server->register_tool(
        name        => 'ok_tool',
        description => 'Succeeds',
        inputSchema => { type => 'object' },
        code        => sub { return 'fine' },
    );
    $server->register_tool(
        name        => 'bad_tool',
        description => 'Fails',
        inputSchema => { type => 'object' },
        code        => sub { die "nope\n" },
    );

    for my $name (qw(ok_tool bad_tool)) {
        my $response = $server->handle(_req(
            id     => 53,
            method => 'tools/call',
            params => _params(
                name      => $name,
                arguments => {},
            ),
        ));
        is(
            $response->{result}{_meta}{'io.modelcontextprotocol/serverInfo'}{name},
            'call-meta-server',
            "serverInfo present for $name",
        );
    }
};

subtest 'tools/call default wrapping: exact encode_json for arrayref and hashref returns' => sub {
    # A hashref's key iteration order is not guaranteed to match between two
    # independently-built hashrefs with identical keys, even within the same
    # process (Perl's per-hash bucket layout, not just a per-process seed) —
    # so the expected-value hashref must be the *same* reference the tool
    # returns, not a fresh literal with equal content, or this test is
    # flaky. Arrays don't have this problem: order is always insertion order.
    my $expected_hash = { a => 1, b => 2 };

    my $server = Net::Async::MCP::Server->new;
    $server->register_tool(
        name        => 'array_tool',
        description => 'Returns an arrayref',
        inputSchema => { type => 'object' },
        code        => sub { return [ 1, 2, 'three' ] },
    );
    $server->register_tool(
        name        => 'hash_tool',
        description => 'Returns a hashref',
        inputSchema => { type => 'object' },
        code        => sub { return $expected_hash },
    );

    my $array_response = $server->handle(_req(
        id     => 54,
        method => 'tools/call',
        params => _params(
            name      => 'array_tool',
            arguments => {},
        ),
    ));
    is(
        $array_response->{result}{content}[0]{text},
        encode_json([ 1, 2, 'three' ]),
        'arrayref return is exact encode_json of the returned value',
    );

    my $hash_response = $server->handle(_req(
        id     => 55,
        method => 'tools/call',
        params => _params(
            name      => 'hash_tool',
            arguments => {},
        ),
    ));
    is(
        $hash_response->{result}{content}[0]{text},
        encode_json($expected_hash),
        'hashref return is exact encode_json of the returned value',
    );
};

subtest 'tools/call default wrapping: undef return becomes empty-string text' => sub {
    my $server = Net::Async::MCP::Server->new;
    $server->register_tool(
        name        => 'undef_tool',
        description => 'Returns undef',
        inputSchema => { type => 'object' },
        code        => sub { return undef },
    );

    my $response = $server->handle(_req(
        id     => 56,
        method => 'tools/call',
        params => _params(
            name      => 'undef_tool',
            arguments => {},
        ),
    ));

    is($response->{result}{content}[0]{text}, '', 'undef return is empty-string text content');
};

subtest 'tools/call rich content: content arrayref and structuredContent pass through verbatim' => sub {
    my $server = Net::Async::MCP::Server->new;
    $server->register_tool(
        name        => 'rich_tool',
        description => 'Returns its own content blocks',
        inputSchema => { type => 'object' },
        code        => sub {
            return {
                content => [
                    { type => 'text',  text => 'first block' },
                    { type => 'image', data => 'ZmFrZQ==', mimeType => 'image/png' },
                ],
                structuredContent => { total => 42 },
            };
        },
    );

    my $response = $server->handle(_req(
        id     => 57,
        method => 'tools/call',
        params => _params(
            name      => 'rich_tool',
            arguments => {},
        ),
    ));

    my $r = $response->{result};
    is($r->{resultType}, 'complete', 'resultType filled in as complete');
    is(scalar @{ $r->{content} }, 2, 'both content blocks passed through');
    is($r->{content}[0]{text}, 'first block', 'first block verbatim');
    is($r->{content}[1]{type}, 'image', 'second block verbatim (not re-wrapped)');
    is($r->{structuredContent}{total}, 42, 'structuredContent passed through');
};

subtest 'tools/call rich content: structuredContent alone gets a serialized text content block' => sub {
    my $server = Net::Async::MCP::Server->new;
    $server->register_tool(
        name        => 'structured_only_tool',
        description => 'Returns only structuredContent',
        inputSchema => { type => 'object' },
        code        => sub {
            return { structuredContent => { ok => JSON::MaybeXS::true() } };
        },
    );

    my $response = $server->handle(_req(
        id     => 58,
        method => 'tools/call',
        params => _params(
            name      => 'structured_only_tool',
            arguments => {},
        ),
    ));

    my $r = $response->{result};
    is($r->{resultType}, 'complete', 'resultType filled in as complete');
    ok($r->{structuredContent}{ok}, 'structuredContent passed through verbatim');
    is(ref $r->{content}, 'ARRAY', 'content key supplied');
    is(scalar @{ $r->{content} }, 1, 'one content block');
    is($r->{content}[0]{type}, 'text', 'block is text');
    is(JSON::MaybeXS::decode_json($r->{content}[0]{text}), { ok => T() },
        'text is the serialized structuredContent');
};

subtest 'tools/call tool returning a Future is awaited before wrapping' => sub {
    my $server = Net::Async::MCP::Server->new;
    $server->register_tool(
        name        => 'future_tool',
        description => 'Returns a Future',
        inputSchema => { type => 'object' },
        code        => sub { return Future->done({ ok => 1 }) },
    );

    my $response = eval { $server->handle(_req(
        id     => 60,
        method => 'tools/call',
        params => _params(
            name      => 'future_tool',
            arguments => {},
        ),
    )) };

    ok($response, 'got response, no exception escaped handle()');
    ok(!exists $response->{error}, 'no JSON-RPC error');
    my $r = $response->{result};
    is($r->{resultType}, 'complete', 'resultType complete');
    like($r->{content}[0]{text}, qr/ok/, 'Future resolved into text content');
};

subtest 'tool annotations and outputSchema pass through into tools/list wire shape' => sub {
    my $server = Net::Async::MCP::Server->new;
    $server->register_tool(
        name         => 'annotated_tool',
        description  => 'Carries annotations and outputSchema',
        inputSchema  => { type => 'object' },
        annotations  => { readOnlyHint => 1, destructiveHint => 0 },
        outputSchema => { type => 'object', properties => { total => { type => 'number' } } },
    );

    my $response = $server->handle(_req(method => 'tools/list', id => 59));

    my $tool = $response->{result}{tools}[0];
    is($tool->{annotations}{readOnlyHint}, 1, 'annotations.readOnlyHint passed through');
    is($tool->{annotations}{destructiveHint}, 0, 'annotations.destructiveHint passed through');
    is($tool->{outputSchema}{type}, 'object', 'outputSchema passed through');
    is(
        $tool->{outputSchema}{properties}{total}{type},
        'number',
        'outputSchema nested detail passed through',
    );
};

subtest 'tools/call isError is a JSON boolean on the wire' => sub {
    my $server = Net::Async::MCP::Server->new;
    $server->register_tool(
        name => 'boom', description => 'Always throws',
        inputSchema => { type => 'object' },
        code => sub { die "boom!\n" },
    );
    $server->register_tool(
        name => 'rich_fail', description => 'Rich content, perl-truthy isError',
        inputSchema => { type => 'object' },
        code => sub { return { content => [ { type => 'text', text => 'x' } ], isError => 1 } },
    );
    $server->register_tool(
        name => 'rich_ok', description => 'Rich content, perl-falsy isError',
        inputSchema => { type => 'object' },
        code => sub { return { content => [ { type => 'text', text => 'x' } ], isError => 0 } },
    );

    my %want = ( boom => 'true', rich_fail => 'true', rich_ok => 'false' );
    for my $name ( sort keys %want ) {
        my $response = $server->handle(_req(
            id => 90, method => 'tools/call',
            params => _params( name => $name, arguments => {} ),
        ));
        my $json = JSON::MaybeXS->new( canonical => 1 )->encode( $response->{result} );
        like( $json, qr/"isError":$want{$name}(?![\w])/, $name.': isError encoded as '.$want{$name} );
        unlike( $json, qr/"isError":[01](?![\w])/, $name.': isError not a number' );
    }
};

subtest 'tools/call isError is a JSON boolean on a resultType passthrough' => sub {
    my $server = Net::Async::MCP::Server->new;
    my $tool_hash = { resultType => 'input_required', content => [ { type => 'text', text => 'x' } ], isError => 1 };
    $server->register_tool(
        name => 'mrtr_fail', description => 'Own resultType, perl-truthy isError',
        inputSchema => { type => 'object' },
        code => sub { return $tool_hash },
    );
    $server->register_tool(
        name => 'mrtr_ok', description => 'Own resultType, perl-falsy isError',
        inputSchema => { type => 'object' },
        code => sub { return { resultType => 'input_required', content => [], isError => 0 } },
    );

    my %want = ( mrtr_fail => 'true', mrtr_ok => 'false' );
    for my $name ( sort keys %want ) {
        my $response = $server->handle(_req(
            id => 91, method => 'tools/call',
            params => _params( name => $name, arguments => {} ),
        ));
        my $json = JSON::MaybeXS->new( canonical => 1 )->encode( $response->{result} );
        like( $json, qr/"isError":$want{$name}(?![\w])/, $name.': isError encoded as '.$want{$name} );
        unlike( $json, qr/"isError":[01](?![\w])/, $name.': isError not a number' );
        like( $json, qr/"resultType":"input_required"/, $name.': own resultType kept' );
    }
    is( $tool_hash->{isError}, 1, 'tool-returned hash not mutated' );
    ok( !exists $tool_hash->{_meta}, 'tool-returned hash got no _meta' );
};

done_testing;
