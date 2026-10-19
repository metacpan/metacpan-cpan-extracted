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

subtest 'supported_versions' => sub {
    my $server = Net::Async::MCP::Server->new;
    my $v = $server->supported_versions;
    ok(ref $v eq 'ARRAY', 'supported_versions returns arrayref');
    ok(grep { $_ eq '2026-07-28' } @{$v}, 'supports 2026-07-28');
};

subtest 'register_tool' => sub {
    my $server = Net::Async::MCP::Server->new;

    $server->register_tool(
        name         => 'test_tool',
        description  => 'A test tool',
        inputSchema  => { type => 'object' },
    );

    my $tools = $server->tools;
    is(scalar @$tools, 1, 'one tool registered');
    is($tools->[0]{name}, 'test_tool', 'tool name');
    is($tools->[0]{inputSchema}{type}, 'object', 'inputSchema preserved');

    # Legacy snake_case alias is normalised to inputSchema at registration time.
    $server = Net::Async::MCP::Server->new;
    $server->register_tool(
        name         => 'legacy_tool',
        description  => 'Legacy',
        input_schema => { type => 'object' },
    );
    is($server->tools->[0]{inputSchema}{type}, 'object', 'input_schema normalised');
};

subtest 'register_tool validates inputSchema' => sub {
    my $server = Net::Async::MCP::Server->new;

    like(
        dies { $server->register_tool(name => 'no_schema', description => 'x') },
        qr/inputSchema/,
        'dies without inputSchema',
    );

    like(
        dies { $server->register_tool(description => 'x', inputSchema => {}) },
        qr/name/,
        'dies without name',
    );
};

subtest 'list_tools returns wire shape' => sub {
    my $server = Net::Async::MCP::Server->new;

    $server->register_tool(
        name         => 'tool1',
        description  => 'First',
        inputSchema  => { type => 'object' },
    );
    $server->register_tool(
        name         => 'tool2',
        title        => 'Second (display)',
        description  => 'Second',
        inputSchema  => { type => 'object' },
    );

    my $tools = $server->list_tools->get;
    is(scalar @$tools, 2, 'two tools listed');
    is([map { $_->{name} } @$tools], ['tool1', 'tool2'], 'tool names');
    ok(exists $tools->[0]{inputSchema}, 'wire shape uses inputSchema');
    ok(!exists $tools->[0]{input_schema}, 'wire shape does not use input_schema');
    is($tools->[1]{title}, 'Second (display)', 'title passes through when set');
};

subtest 'duplicate registration croaks' => sub {
    my $server = Net::Async::MCP::Server->new;

    $server->register_tool(
        name => 't', description => 'first', inputSchema => { type => 'object' },
    );
    like(
        dies { $server->register_tool(
            name => 't', description => 'second', inputSchema => { type => 'object' },
        ) },
        qr/Tool 't' is already registered/,
        'duplicate tool name croaks',
    );
    is([map { $_->{description} } @{ $server->tools }], ['first'],
        'first tool registration kept, none appended');

    $server->register_resource( uri => 'file:///a', name => 'a' );
    like(
        dies { $server->register_resource( uri => 'file:///a', name => 'other' ) },
        qr{Resource 'file:///a' is already registered},
        'duplicate resource uri croaks',
    );
    is(scalar @{ $server->resources }, 1, 'one resource kept');

    $server->register_prompt( name => 'p' );
    like(
        dies { $server->register_prompt( name => 'p' ) },
        qr/Prompt 'p' is already registered/,
        'duplicate prompt name croaks',
    );
    is(scalar @{ $server->prompts }, 1, 'one prompt kept');

    # Same key across different kinds is not a duplicate.
    ok(lives { $server->register_prompt( name => 't' ) },
        'prompt may share a name with a tool');
};

subtest 'discover' => sub {
    my $server = Net::Async::MCP::Server->new;
    my $result = $server->discover->get;

    is($result->{resultType}, 'complete', 'resultType complete');
    ok(grep { $_ eq '2026-07-28' } @{$result->{supportedVersions}}, 'advertises 2026-07-28');
    ok(exists $result->{capabilities}, 'capabilities returned');
    ok(defined $result->{ttlMs}, 'ttlMs present');
    ok(defined $result->{cacheScope}, 'cacheScope present');
};

subtest 'server_capabilities' => sub {
    my $server = Net::Async::MCP::Server->new;

    $server->register_tool(
        name         => 'test',
        description  => 'Test',
        inputSchema  => { type => 'object' },
    );

    my $caps = $server->server_capabilities;
    ok(defined $caps, 'capabilities returned');
    ok(exists $caps->{tools}, 'tools capability present');
};

done_testing;
