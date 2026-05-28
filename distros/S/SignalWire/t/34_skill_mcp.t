#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use SignalWire::Agent::AgentBase;
use SignalWire::Skills::SkillRegistry;

my $factory = SignalWire::Skills::SkillRegistry->get_factory('mcp_gateway');
ok(defined $factory, 'factory found');

subtest 'construction' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'mcp');
    my $skill = $factory->new(agent => $agent, params => {});
    is($skill->skill_name, 'mcp_gateway', 'skill_name');
    ok(!$skill->supports_multiple_instances, 'no multi-instance');
};

subtest 'registers tools per service' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'mcp_reg');
    my $skill = $factory->new(agent => $agent, params => {
        services => [
            { name => 'weather' },
            { name => 'search' },
        ],
    });
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{mcp_weather}, 'mcp_weather tool');
    ok(exists $agent->tools->{mcp_search}, 'mcp_search tool');
};

subtest 'custom prefix' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'mcp_prefix');
    my $skill = $factory->new(agent => $agent, params => {
        tool_prefix => 'gateway_',
        services    => [{ name => 'test' }],
    });
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{gateway_test}, 'custom prefix');
};

subtest 'hints include service names' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'mcp_hints');
    my $skill = $factory->new(agent => $agent, params => {
        services => [{ name => 'myservice' }],
    });
    my $hints = $skill->get_hints;
    ok(grep({ $_ eq 'MCP' } @$hints), 'MCP hint');
    ok(grep({ $_ eq 'myservice' } @$hints), 'service name hint');
};

subtest 'global data' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'mcp_gd');
    my $skill = $factory->new(agent => $agent, params => {
        gateway_url => 'https://gw.example.com',
    });
    my $gdata = $skill->get_global_data;
    is($gdata->{mcp_gateway_url}, 'https://gw.example.com', 'gateway_url');
};

subtest 'prompt sections' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'mcp_ps');
    my $skill = $factory->new(agent => $agent, params => {});
    my $sections = $skill->get_prompt_sections;
    like($sections->[0]{title}, qr/MCP/, 'title mentions MCP');
};

subtest 'parameter schema' => sub {
    my $schema = $factory->get_parameter_schema;
    ok(exists $schema->{gateway_url}, 'has gateway_url');
    ok(exists $schema->{services}, 'has services');
};

done_testing;
