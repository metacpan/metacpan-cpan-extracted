use strict;
use warnings;

use Test2::V0;

use IO::Handle;
use JSON::MaybeXS qw( encode_json decode_json );

use Net::Async::MCP::Server;
use Net::Async::MCP::Server::Transport::Stdio;

sub _line {
    my ( $id, $method, $params ) = @_;
    my %request = (
        jsonrpc => '2.0',
        method  => $method,
        defined $id ? ( id => $id ) : (),
        defined $params ? ( params => $params ) : (),
    );
    return encode_json(\%request) . "\n";
}

sub _decode_lines {
    my ( $text ) = @_;
    return [ map { decode_json($_) } grep { length } split /\n/, ( $text // '' ) ];
}

sub _server {
    my ( %params ) = @_;
    my $server = Net::Async::MCP::Server->new(
        name => 'legacy-stdio-test',
        %params,
    );
    $server->register_tool(
        name        => 'inspect',
        description => 'Returns rich results',
        inputSchema => { type => 'object' },
        code        => sub {
            my ( $arguments ) = @_;
            return {
                content => [
                    {
                        type => 'text',
                        text => $arguments->{text},
                    },
                ],
                structuredContent => { echoed => $arguments->{text} },
            };
        },
    );
    $server->register_tool(
        name        => 'broken',
        description => 'Fails deliberately',
        inputSchema => { type => 'object' },
        code        => sub { die "broken tool\n" },
    );
    $server->register_resource(
        uri  => 'sunriser://legacy-capability-test',
        name => 'Legacy capability test resource',
        code => sub { return 'resource content' },
    );
    $server->register_prompt(
        name => 'legacy_capability_test',
        code => sub { return 'prompt content' },
    );
    return $server;
}

sub _run_stdio {
    my ( $server, @lines ) = @_;

    pipe( my $read_handle, my $write_handle ) or die 'pipe: '.$!;
    $write_handle->autoflush(1);

    open my $output_handle, '>', \my $output or die 'open scalar handle: '.$!;
    $output_handle->autoflush(1);

    my $transport = Net::Async::MCP::Server::Transport::Stdio->new(
        server       => $server,
        read_handle  => $read_handle,
        write_handle => $output_handle,
    );

    print {$write_handle} @lines;
    close $write_handle;
    $transport->handle_requests;

    return _decode_lines($output);
}

subtest 'default server remains strict 2026-only' => sub {
    my $server = _server();

    my $response = $server->handle({
        jsonrpc => '2.0',
        id      => 1,
        method  => 'initialize',
        params  => {
            _meta => {
                'io.modelcontextprotocol/protocolVersion'    => '2026-07-28',
                'io.modelcontextprotocol/clientCapabilities' => {},
            },
        },
    });

    is($response->{error}{code}, -32601, 'initialize remains unknown by default');
};

subtest 'legacy_compat accepts 2025-11-25 on stdio without changing 2026' => sub {
    my $server = _server(legacy_compat => 1);

    my $responses = _run_stdio(
        $server,
        _line(1, 'initialize', {
            protocolVersion => '2025-11-25',
            capabilities    => {},
            clientInfo      => {
                name    => 'claude-code',
                version => '2.1.263',
            },
        }),
        _line(undef, 'notifications/initialized', {}),
        _line(2, 'ping'),
        _line(3, 'tools/list', {}),
        _line(4, 'tools/call', {
            name      => 'inspect',
            arguments => { text => 'hello' },
        }),
        _line(5, 'tools/call', {
            name      => 'broken',
            arguments => {},
        }),
        _line(6, 'server/discover', {
            _meta => {
                'io.modelcontextprotocol/protocolVersion'    => '2026-07-28',
                'io.modelcontextprotocol/clientCapabilities' => {},
            },
        }),
        _line(7, 'tools/list', {
            _meta => {
                'io.modelcontextprotocol/protocolVersion'    => '2026-07-28',
                'io.modelcontextprotocol/clientCapabilities' => {},
            },
        }),
        _line(8, 'tools/call', {
            _meta => {
                'io.modelcontextprotocol/protocolVersion'    => '2026-07-28',
                'io.modelcontextprotocol/clientCapabilities' => {},
            },
            name      => 'inspect',
            arguments => { text => 'new protocol' },
        }),
    );

    is(scalar @$responses, 8, 'one response per request, none for initialized notification');

    my ($initialize, $ping, $list, $call, $tool_error, $discover, $new_list, $new_call) = @$responses;

    is($initialize->{id}, 1, 'initialize response id');
    is([sort keys %{ $initialize->{result} }], [qw( capabilities protocolVersion serverInfo )], 'initialize has only legacy result fields');
    is($initialize->{result}{protocolVersion}, '2025-11-25', 'initialize selects the offered legacy version');
    is($initialize->{result}{serverInfo}{name}, 'legacy-stdio-test', 'initialize includes serverInfo');
    is(
        $initialize->{result}{capabilities},
        { tools => {} },
        'legacy initialize advertises only supported tools',
    );

    is($ping->{id}, 2, 'ping response id');
    is($ping->{result}, {}, 'ping has the required empty result');

    is($list->{id}, 3, 'tools/list response id');
    is([sort keys %{ $list->{result} }], ['tools'], 'tools/list has only the legacy tools field');
    is($list->{result}{tools}[0]{name}, 'inspect', 'tools/list serializes the registered tool');
    ok(exists $list->{result}{tools}[0]{inputSchema}, 'tools/list preserves inputSchema');
    ok(!exists $list->{result}{tools}[0]{code}, 'tools/list never serializes the implementation coderef');

    is($call->{id}, 4, 'tools/call response id');
    is([sort keys %{ $call->{result} }], [qw( content isError structuredContent )], 'tools/call has only 2025 result fields');
    is($call->{result}{content}[0]{text}, 'hello', 'tools/call preserves rich text content');
    is($call->{result}{structuredContent}{echoed}, 'hello', 'tools/call preserves structuredContent');
    ok(exists $call->{result}{isError}, 'tools/call explicitly says isError false');
    ok(!$call->{result}{isError}, 'tools/call isError is false on success');
    ok(!exists $call->{result}{resultType}, 'tools/call does not leak a 2026 resultType');
    ok(!exists $call->{result}{_meta}, 'tools/call does not leak 2026 metadata');

    is($tool_error->{id}, 5, 'tool error response id');
    is([sort keys %{ $tool_error->{result} }], [qw( content isError )], 'tool error has only 2025 result fields');
    ok($tool_error->{result}{isError}, 'tool errors use isError');
    like($tool_error->{result}{content}[0]{text}, qr/broken tool/, 'tool error text is returned to the client');

    is($discover->{id}, 6, '2026 discover response id');
    is($discover->{result}{resultType}, 'complete', '2026 resultType is unchanged in compatibility mode');
    is(
        $discover->{result}{_meta}{'io.modelcontextprotocol/serverInfo'}{name},
        'legacy-stdio-test',
        '2026 metadata is unchanged in compatibility mode',
    );
    ok(exists $discover->{result}{capabilities}{resources}, '2026 discover still advertises resources');
    ok(exists $discover->{result}{capabilities}{prompts}, '2026 discover still advertises prompts');

    is($new_list->{id}, 7, '2026 tools/list response id');
    is($new_list->{result}{resultType}, 'complete', '2026 tools/list keeps resultType');
    is($new_list->{result}{tools}[0]{name}, 'inspect', '2026 tools/list remains available');

    is($new_call->{id}, 8, '2026 tools/call response id');
    is($new_call->{result}{resultType}, 'complete', '2026 tools/call keeps resultType');
    is($new_call->{result}{content}[0]{text}, 'new protocol', '2026 tools/call remains available');
};

subtest 'legacy tools/call with non-hash params returns -32602' => sub {
    my $server = _server( legacy_compat => 1 );
    for my $bad ( [ 'array', [] ], [ 'string', 'oops' ], [ 'number', 42 ] ) {
        my ( $label, $params ) = @$bad;
        my $res;
        ok(
            lives { $res = $server->handle(
                { jsonrpc => '2.0', id => 9, method => 'tools/call', params => $params },
                { transport => 'stdio' },
            ) },
            'handle() does not die for '.$label.' params',
        ) or next;
        is( $res->{error}{code}, -32602, $label.' params: Invalid params' );
        is( $res->{id}, 9, $label.' params: id preserved' );
    }
};

subtest 'legacy tools/call with non-hash arguments returns -32602' => sub {
    my $server = _server( legacy_compat => 1 );
    for my $bad ( [ 'array', [] ], [ 'string', 'oops' ], [ 'number', 42 ] ) {
        my ( $label, $arguments ) = @$bad;
        my $res;
        ok(
            lives { $res = $server->handle(
                {
                    jsonrpc => '2.0', id => 10, method => 'tools/call',
                    params  => { name => 'inspect', arguments => $arguments },
                },
                { transport => 'stdio' },
            ) },
            'handle() does not die for '.$label.' arguments',
        ) or next;
        is( $res->{error}{code}, -32602, $label.' arguments: Invalid params' );
        like( $res->{error}{message}, qr/arguments must be an object/, $label.' arguments: message' );
        is( $res->{id}, 10, $label.' arguments: id preserved' );
    }

    my $res = $server->handle(
        {
            jsonrpc => '2.0', id => 11, method => 'tools/call',
            params  => { name => 'inspect' },
        },
        { transport => 'stdio' },
    );
    ok( !$res->{error}, 'missing arguments still accepted' );
};

subtest 'context without transport does not warn' => sub {
    my $server = _server( legacy_compat => 1 );
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    $server->handle(
        { jsonrpc => '2.0', id => 1, method => 'tools/list' },
        {},
    );
    is( \@warn, [], 'no uninitialized warning' );
};

done_testing;
