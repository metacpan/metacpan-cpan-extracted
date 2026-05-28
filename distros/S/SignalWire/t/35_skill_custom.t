#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use SignalWire::Agent::AgentBase;
use SignalWire::Skills::SkillRegistry;

my $factory = SignalWire::Skills::SkillRegistry->get_factory('custom_skills');
ok(defined $factory, 'factory found');

subtest 'construction' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'cs');
    my $skill = $factory->new(agent => $agent, params => {});
    is($skill->skill_name, 'custom_skills', 'skill_name');
    ok($skill->supports_multiple_instances, 'multi-instance');
};

subtest 'registers define_tool style' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'cs_define');
    my $skill = $factory->new(agent => $agent, params => {
        tools => [
            { name => 'my_tool', description => 'Custom tool', handler => sub { {} } },
        ],
    });
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{my_tool}, 'my_tool registered');
};

subtest 'registers swaig_function style' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'cs_swaig');
    my $skill = $factory->new(agent => $agent, params => {
        tools => [
            {
                function    => 'dm_tool',
                description => 'DataMap tool',
                parameters  => { type => 'object', properties => {} },
                data_map    => { webhooks => [] },
            },
        ],
    });
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{dm_tool}, 'dm_tool registered via swaig');
};

subtest 'mixed tools' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'cs_mix');
    my $skill = $factory->new(agent => $agent, params => {
        tools => [
            { name => 'tool_a', description => 'A' },
            { function => 'tool_b', description => 'B', parameters => {} },
        ],
    });
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{tool_a}, 'tool_a');
    ok(exists $agent->tools->{tool_b}, 'tool_b');
};

subtest 'empty tools array' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'cs_empty');
    my $skill = $factory->new(agent => $agent, params => { tools => [] });
    $skill->setup;
    $skill->register_tools;
    is(scalar keys %{$agent->tools}, 0, 'no tools registered');
};

subtest 'skips invalid entries' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'cs_skip');
    my $skill = $factory->new(agent => $agent, params => {
        tools => ['not_a_hash', undef, { name => 'valid', description => 'V' }],
    });
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{valid}, 'valid tool registered');
    is(scalar keys %{$agent->tools}, 1, 'only valid tool');
};

subtest 'parameter schema' => sub {
    my $schema = $factory->get_parameter_schema;
    ok(exists $schema->{tools}, 'has tools');
};

done_testing;
