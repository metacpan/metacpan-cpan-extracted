#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use SignalWire::Agent::AgentBase;
use SignalWire::Skills::SkillRegistry;

my $factory = SignalWire::Skills::SkillRegistry->get_factory('spider');
ok(defined $factory, 'factory found');

subtest 'construction' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'sp');
    my $skill = $factory->new(agent => $agent, params => {});
    is($skill->skill_name, 'spider', 'skill_name');
    ok($skill->supports_multiple_instances, 'multi-instance');
};

subtest 'registers 3 tools' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'sp_reg');
    my $skill = $factory->new(agent => $agent, params => {});
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{scrape_url}, 'scrape_url');
    ok(exists $agent->tools->{crawl_site}, 'crawl_site');
    ok(exists $agent->tools->{extract_structured_data}, 'extract_structured_data');
};

subtest 'hints' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'sp_hints');
    my $skill = $factory->new(agent => $agent, params => {});
    my $hints = $skill->get_hints;
    ok(scalar @$hints > 0, 'has hints');
    ok(grep({ $_ eq 'spider' } @$hints), 'includes spider');
    ok(grep({ $_ eq 'scrape' } @$hints), 'includes scrape');
};

subtest 'tool execution against fixture' => sub {
    # Spider issues real outbound HTTP. To verify the dispatch path
    # deterministically — without depending on example.com being up
    # and serving stable text — point the skill at a local HTTP::Tiny
    # fixture by setting SPIDER_BASE_URL.
    require Plack::Test;
    require Plack::Request;
    my $app = sub {
        my $env = shift;
        return [
            200,
            ['Content-Type', 'text/html'],
            ["<html><body>Test page sentinel zazzle</body></html>"],
        ];
    };
    require HTTP::Server::PSGI;
    require IO::Socket::INET;
    my $listen = IO::Socket::INET->new(
        Listen    => 5,
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Proto     => 'tcp',
        ReuseAddr => 1,
    );
    my $port = $listen->sockport;
    close $listen;

    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        my $server = HTTP::Server::PSGI->new(
            host => '127.0.0.1',
            port => $port,
        );
        $server->run($app);
        exit 0;
    }

    # Wait for the server to come up.
    my $up = 0;
    for (1..30) {
        my $sock = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1',
            PeerPort => $port,
            Timeout  => 1,
        );
        if ($sock) { $up = 1; close $sock; last }
        select(undef, undef, undef, 0.1);
    }

    eval {
        local $ENV{SPIDER_BASE_URL} = "http://127.0.0.1:$port";
        my $agent = SignalWire::Agent::AgentBase->new(name => 'sp_exec');
        my $skill = $factory->new(agent => $agent, params => {});
        $skill->setup;
        $skill->register_tools;
        my $result = $agent->on_function_call(
            'scrape_url',
            { url => 'https://upstream.invalid/somepage' },
            {},
        );
        ok(defined $result, 'scrape returns result');
        like($result->response, qr/zazzle/, 'mentions fixture sentinel from real HTTP');
    };
    my $err = $@;

    # Always reap.
    kill 'TERM', $pid;
    waitpid($pid, 0);
    die $err if $err;
};

subtest 'parameter schema' => sub {
    my $schema = $factory->get_parameter_schema;
    ok(exists $schema->{max_pages}, 'has max_pages');
    ok(exists $schema->{timeout}, 'has timeout');
};

done_testing;
