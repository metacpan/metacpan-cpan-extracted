#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON qw(encode_json decode_json);
use MIME::Base64 qw(encode_base64);

use_ok('SignalWire::Agents::Server::AgentServer');
use_ok('SignalWire::Agents::Agent::AgentBase');

# ============================================================
# 1. Server construction
# ============================================================
subtest 'server construction' => sub {
    my $server = SignalWire::Agents::Server::AgentServer->new;
    is($server->host, '0.0.0.0', 'default host');
    ok($server->port, 'port has value');
    is(ref $server->agents, 'HASH', 'agents is hashref');
    is(scalar keys %{$server->agents}, 0, 'no agents initially');
};

# ============================================================
# 2. Register agent
# ============================================================
subtest 'register agent' => sub {
    my $server = SignalWire::Agents::Server::AgentServer->new;
    my $agent  = SignalWire::Agents::Agent::AgentBase->new(
        name  => 'support',
        route => '/support',
    );

    $server->register($agent);
    ok(exists $server->agents->{'/support'}, 'agent registered at /support');
    is($server->agents->{'/support'}->name, 'support', 'agent name matches');
};

# ============================================================
# 3. Register with route override
# ============================================================
subtest 'register with route override' => sub {
    my $server = SignalWire::Agents::Server::AgentServer->new;
    my $agent  = SignalWire::Agents::Agent::AgentBase->new(
        name  => 'sales',
        route => '/original',
    );

    $server->register($agent, '/sales');
    ok(exists $server->agents->{'/sales'}, 'agent at overridden route');
    is($agent->route, '/sales', 'agent route updated');
};

# ============================================================
# 4. Register duplicate route
# ============================================================
subtest 'register duplicate route' => sub {
    my $server = SignalWire::Agents::Server::AgentServer->new;
    my $agent1 = SignalWire::Agents::Agent::AgentBase->new(name => 'a1', route => '/test');
    my $agent2 = SignalWire::Agents::Agent::AgentBase->new(name => 'a2', route => '/test');

    $server->register($agent1);
    eval { $server->register($agent2) };
    like($@, qr/already registered/, 'duplicate route throws error');
};

# ============================================================
# 5. Unregister agent
# ============================================================
subtest 'unregister agent' => sub {
    my $server = SignalWire::Agents::Server::AgentServer->new;
    my $agent  = SignalWire::Agents::Agent::AgentBase->new(name => 'temp', route => '/temp');

    $server->register($agent);
    ok(exists $server->agents->{'/temp'}, 'agent registered');

    $server->unregister('/temp');
    ok(!exists $server->agents->{'/temp'}, 'agent unregistered');
};

# ============================================================
# 6. List agents
# ============================================================
subtest 'list agents' => sub {
    my $server = SignalWire::Agents::Server::AgentServer->new;
    $server->register(
        SignalWire::Agents::Agent::AgentBase->new(name => 'a', route => '/a')
    );
    $server->register(
        SignalWire::Agents::Agent::AgentBase->new(name => 'b', route => '/b')
    );

    my $list = $server->list_agents;
    is(scalar @$list, 2, 'two agents listed');
    ok(grep({ $_ eq '/a' } @$list), '/a listed');
    ok(grep({ $_ eq '/b' } @$list), '/b listed');
};

# ============================================================
# 7. Get agent
# ============================================================
subtest 'get agent' => sub {
    my $server = SignalWire::Agents::Server::AgentServer->new;
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'x', route => '/x');
    $server->register($agent);

    my $found = $server->get_agent('/x');
    is($found, $agent, 'get_agent returns the agent');

    my $missing = $server->get_agent('/y');
    ok(!defined $missing, 'get_agent returns undef for missing');
};

# ============================================================
# 8. PSGI app construction
# ============================================================
subtest 'psgi_app construction' => sub {
    my $server = SignalWire::Agents::Server::AgentServer->new;
    $server->register(
        SignalWire::Agents::Agent::AgentBase->new(name => 'test', route => '/test')
    );

    my $app = $server->psgi_app;
    is(ref $app, 'CODE', 'psgi_app returns coderef');
};

# ============================================================
# 9. Health endpoint
# ============================================================
subtest 'health endpoint' => sub {
    my $server = SignalWire::Agents::Server::AgentServer->new;
    $server->register(
        SignalWire::Agents::Agent::AgentBase->new(name => 'agent1', route => '/agent1')
    );

    my $app = $server->psgi_app;
    my $res = $app->({
        REQUEST_METHOD => 'GET',
        PATH_INFO      => '/health',
        SCRIPT_NAME    => '',
        SERVER_NAME    => 'localhost',
        SERVER_PORT    => 3000,
    });

    is($res->[0], 200, 'health returns 200');
    my $body = decode_json($res->[2][0]);
    is($body->{status}, 'healthy', 'status is healthy');
    ok(exists $body->{agents}, 'agents list in response');
};

# ============================================================
# 10. Ready endpoint
# ============================================================
subtest 'ready endpoint' => sub {
    my $server = SignalWire::Agents::Server::AgentServer->new;
    my $app = $server->psgi_app;
    my $res = $app->({
        REQUEST_METHOD => 'GET',
        PATH_INFO      => '/ready',
        SCRIPT_NAME    => '',
        SERVER_NAME    => 'localhost',
        SERVER_PORT    => 3000,
    });

    is($res->[0], 200, 'ready returns 200');
    my $body = decode_json($res->[2][0]);
    is($body->{status}, 'ready', 'status is ready');
};

# ============================================================
# 11. Agent routing through server
# ============================================================
subtest 'agent routing' => sub {
    my $server = SignalWire::Agents::Server::AgentServer->new;
    my $agent  = SignalWire::Agents::Agent::AgentBase->new(
        name               => 'routed',
        route              => '/routed',
        basic_auth_user     => 'user',
        basic_auth_password => 'pass',
    );
    $server->register($agent);

    my $app = $server->psgi_app;

    # Access the agent endpoint with auth
    my $auth = encode_base64('user:pass', '');
    my $res = $app->({
        REQUEST_METHOD     => 'GET',
        PATH_INFO          => '/routed',
        SCRIPT_NAME        => '',
        SERVER_NAME        => 'localhost',
        SERVER_PORT        => 3000,
        HTTP_AUTHORIZATION => "Basic $auth",
        'psgi.input'       => do { open my $fh, '<', \(''); $fh },
    });

    is($res->[0], 200, 'routed agent responds 200');
    my $body = decode_json($res->[2][0]);
    is($body->{version}, '1.0.0', 'returns SWML from routed agent');
};

# ============================================================
# 12. 404 for unregistered route
# ============================================================
subtest '404 for unknown route' => sub {
    my $server = SignalWire::Agents::Server::AgentServer->new;
    my $app = $server->psgi_app;
    my $res = $app->({
        REQUEST_METHOD => 'GET',
        PATH_INFO      => '/unknown',
        SCRIPT_NAME    => '',
        SERVER_NAME    => 'localhost',
        SERVER_PORT    => 3000,
    });
    is($res->[0], 404, 'unknown route returns 404');
};

# ============================================================
# 13. Security headers on server responses
# ============================================================
subtest 'security headers' => sub {
    my $server = SignalWire::Agents::Server::AgentServer->new;
    my $app = $server->psgi_app;
    my $res = $app->({
        REQUEST_METHOD => 'GET',
        PATH_INFO      => '/health',
        SCRIPT_NAME    => '',
        SERVER_NAME    => 'localhost',
        SERVER_PORT    => 3000,
    });

    my %headers = @{ $res->[1] };
    is($headers{'X-Content-Type-Options'}, 'nosniff', 'nosniff header');
    is($headers{'X-Frame-Options'}, 'DENY', 'DENY frame header');
    is($headers{'Cache-Control'}, 'no-store', 'no-store cache header');
};

# ============================================================
# 14. Multiple agents routing
# ============================================================
subtest 'multiple agents routing' => sub {
    my $server = SignalWire::Agents::Server::AgentServer->new;
    my $agent_a = SignalWire::Agents::Agent::AgentBase->new(
        name               => 'alpha',
        route              => '/alpha',
        basic_auth_user     => 'user',
        basic_auth_password => 'pass',
    );
    my $agent_b = SignalWire::Agents::Agent::AgentBase->new(
        name               => 'beta',
        route              => '/beta',
        basic_auth_user     => 'user',
        basic_auth_password => 'pass',
    );
    $server->register($agent_a);
    $server->register($agent_b);

    my $app = $server->psgi_app;
    my $auth = encode_base64('user:pass', '');

    for my $route ('/alpha', '/beta') {
        my $res = $app->({
            REQUEST_METHOD     => 'GET',
            PATH_INFO          => $route,
            SCRIPT_NAME        => '',
            SERVER_NAME        => 'localhost',
            SERVER_PORT        => 3000,
            HTTP_AUTHORIZATION => "Basic $auth",
            'psgi.input'       => do { open my $fh, '<', \(''); $fh },
        });
        is($res->[0], 200, "$route returns 200");
    }
};

# ============================================================
# 15. Route normalization
# ============================================================
subtest 'route normalization' => sub {
    my $server = SignalWire::Agents::Server::AgentServer->new;
    my $agent  = SignalWire::Agents::Agent::AgentBase->new(name => 'norm');

    $server->register($agent, 'no_slash');
    ok(exists $server->agents->{'/no_slash'}, 'route normalized with leading /');
};

# ============================================================
# 16. Method chaining on register
# ============================================================
subtest 'method chaining' => sub {
    my $server = SignalWire::Agents::Server::AgentServer->new;
    my $ret = $server->register(
        SignalWire::Agents::Agent::AgentBase->new(name => 'chain', route => '/chain')
    );
    is($ret, $server, 'register returns server for chaining');
};

done_testing;
