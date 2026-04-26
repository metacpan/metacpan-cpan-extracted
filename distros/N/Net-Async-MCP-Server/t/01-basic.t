use strict;
use warnings;

use Test2::V0;
use Net::Async::MCP::Server;

subtest 'server creation' => sub {
    my $server = Net::Async::MCP::Server->new;
    ok($server, 'server created');

    is($server->name, 'NetAsyncMCPServer', 'default name');

    $server = Net::Async::MCP::Server->new(name => 'test-server');
    is($server->name, 'test-server', 'custom name');
};

subtest 'server_info' => sub {
    my $server = Net::Async::MCP::Server->new(name => 'my-server');
    my $info = $server->server_info;

    is($info->{name}, 'my-server', 'server_info name');
    ok(defined $info->{version}, 'server_info has version');
};

subtest 'initialize' => sub {
    my $server = Net::Async::MCP::Server->new;
    my $result = $server->initialize->get;

    is($result->{protocolVersion}, '2025-11-25', 'protocol version');
    is($result->{serverInfo}{name}, 'NetAsyncMCPServer', 'server info in initialize result');
    ok(defined $result->{capabilities}, 'capabilities returned');
};

subtest 'register_tool' => sub {
    my $server = Net::Async::MCP::Server->new;

    $server->register_tool(
        name        => 'test_tool',
        description => 'A test tool',
        input_schema => { type => 'object' },
    );

    my $tools = $server->tools;
    is(scalar @$tools, 1, 'one tool registered');
    is($tools->[0]{name}, 'test_tool', 'tool name');
};

subtest 'list_tools' => sub {
    my $server = Net::Async::MCP::Server->new;

    $server->register_tool(name => 'tool1', description => 'First');
    $server->register_tool(name => 'tool2', description => 'Second');

    my $tools = $server->list_tools->get;
    is(scalar @$tools, 2, 'two tools listed');
    is([map { $_->{name} } @$tools], ['tool1', 'tool2'], 'tool names');
};

subtest 'handle - initialize request' => sub {
    my $server = Net::Async::MCP::Server->new;

    my $request = {
        jsonrpc => '2.0',
        id      => 1,
        method  => 'initialize',
        params  => {},
    };

    my $response = $server->handle($request);

    ok($response, 'got response');
    is($response->{id}, 1, 'response id matches');
    is($response->{result}{protocolVersion}, '2025-11-25', 'protocol version in result');
};

subtest 'handle - tools/list request' => sub {
    my $server = Net::Async::MCP::Server->new;
    $server->register_tool(name => 'my_tool', description => 'A tool');

    my $request = {
        jsonrpc => '2.0',
        id      => 2,
        method  => 'tools/list',
    };

    my $response = $server->handle($request);

    ok($response, 'got response');
    is($response->{id}, 2, 'response id matches');
    is($response->{result}{tools}[0]{name}, 'my_tool', 'tool in result');
};

subtest 'handle - tools/call request' => sub {
    my $server = Net::Async::MCP::Server->new;
    $server->register_tool(
        name    => 'echo',
        description => 'Echoes input',
        code    => sub {
            my ($args) = @_;
            return { echoed => $args->{value} };
        },
    );

    my $request = {
        jsonrpc => '2.0',
        id      => 3,
        method  => 'tools/call',
        params  => {
            name      => 'echo',
            arguments => { value => 'hello' },
        },
    };

    my $response = $server->handle($request);

    ok($response, 'got response');
    is($response->{id}, 3, 'response id matches');
};

subtest 'handle - ping request' => sub {
    my $server = Net::Async::MCP::Server->new;

    my $request = {
        jsonrpc => '2.0',
        id      => 4,
        method  => 'ping',
    };

    my $response = $server->handle($request);

    ok($response, 'got response');
    is($response->{id}, 4, 'response id matches');
    is($response->{result}, {}, 'ping result is empty');
};

subtest 'handle - notifications/initialized' => sub {
    my $server = Net::Async::MCP::Server->new;

    my $request = {
        jsonrpc => '2.0',
        method  => 'notifications/initialized',
    };

    my $response = $server->handle($request);

    is($response, undef, 'notification returns undef');
};

subtest 'handle - unknown method' => sub {
    my $server = Net::Async::MCP::Server->new;

    my $request = {
        jsonrpc => '2.0',
        id      => 5,
        method  => 'unknown/method',
    };

    my $response = $server->handle($request);

    ok($response, 'got error response');
    is($response->{id}, 5, 'response id matches');
    is($response->{error}{code}, -32601, 'method not found error code');
};

subtest 'handle - missing method' => sub {
    my $server = Net::Async::MCP::Server->new;

    my $request = {
        jsonrpc => '2.0',
        id      => 6,
    };

    my $response = $server->handle($request);

    ok($response, 'got error response');
    is($response->{error}{code}, -32600, 'invalid request error code');
};

subtest 'handle - invalid jsonrpc' => sub {
    my $server = Net::Async::MCP::Server->new;

    my $request = {
        id      => 7,
    };

    my $response = $server->handle($request);

    ok($response, 'got error response');
    is($response->{error}{code}, -32600, 'missing method error code');
};

subtest 'server_capabilities' => sub {
    my $server = Net::Async::MCP::Server->new;

    $server->register_tool(name => 'test', description => 'Test');

    my $caps = $server->server_capabilities;
    ok(defined $caps, 'capabilities returned');
};

done_testing;
