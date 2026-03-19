#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use SignalWire::Agents::Agent::AgentBase;
use SignalWire::Agents::Skills::SkillRegistry;

my $factory = SignalWire::Agents::Skills::SkillRegistry->get_factory('api_ninjas_trivia');
ok(defined $factory, 'factory found');

subtest 'construction' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'trivia');
    my $skill = $factory->new(agent => $agent, params => {});
    is($skill->skill_name, 'api_ninjas_trivia', 'skill_name');
    ok($skill->supports_multiple_instances, 'multi-instance');
};

subtest 'registers tool' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'trivia_reg');
    my $skill = $factory->new(agent => $agent, params => {});
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{get_trivia}, 'get_trivia registered');
    my $enum = $agent->tools->{get_trivia}{parameters}{properties}{category}{enum};
    ok(scalar @$enum > 10, 'many categories');
};

subtest 'custom tool_name and categories' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'trivia_custom');
    my $skill = $factory->new(agent => $agent, params => {
        tool_name  => 'quiz',
        categories => ['music', 'sportsleisure'],
    });
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{quiz}, 'custom tool name');
    my $enum = $agent->tools->{quiz}{parameters}{properties}{category}{enum};
    is_deeply($enum, ['music', 'sportsleisure'], 'custom categories');
};

subtest 'instance key with tool_name' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'trivia_key');
    my $skill = $factory->new(agent => $agent, params => { tool_name => 'my_trivia' });
    is($skill->get_instance_key, 'api_ninjas_trivia:my_trivia', 'custom instance key');
};

subtest 'parameter schema' => sub {
    my $schema = $factory->get_parameter_schema;
    ok(exists $schema->{api_key}, 'has api_key');
    ok(exists $schema->{categories}, 'has categories');
};

done_testing;
