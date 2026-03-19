#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use SignalWire::Agents::Agent::AgentBase;
use SignalWire::Agents::Skills::SkillRegistry;

my $factory = SignalWire::Agents::Skills::SkillRegistry->get_factory('native_vector_search');
ok(defined $factory, 'factory found');

subtest 'construction' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'vs');
    my $skill = $factory->new(agent => $agent, params => {});
    is($skill->skill_name, 'native_vector_search', 'skill_name');
    ok($skill->supports_multiple_instances, 'multi-instance');
};

subtest 'registers tool' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'vs_reg');
    my $skill = $factory->new(agent => $agent, params => {});
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{search_knowledge}, 'default tool name');
};

subtest 'custom tool_name and description' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'vs_custom');
    my $skill = $factory->new(agent => $agent, params => {
        tool_name   => 'find_docs',
        description => 'Find documentation',
    });
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{find_docs}, 'custom tool name');
    is($agent->tools->{find_docs}{description}, 'Find documentation', 'custom description');
};

subtest 'hints' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'vs_hints');
    my $skill = $factory->new(agent => $agent, params => { hints => ['tutorial', 'guide'] });
    my $hints = $skill->get_hints;
    ok(grep({ $_ eq 'search' } @$hints), 'base hint search');
    ok(grep({ $_ eq 'tutorial' } @$hints), 'custom hint tutorial');
};

subtest 'prompt sections' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'vs_ps');
    my $skill = $factory->new(agent => $agent, params => {});
    my $sections = $skill->get_prompt_sections;
    is($sections->[0]{title}, 'Knowledge Search', 'title');
};

subtest 'parameter schema' => sub {
    my $schema = $factory->get_parameter_schema;
    ok(exists $schema->{remote_url}, 'has remote_url');
    ok(exists $schema->{index_name}, 'has index_name');
};

done_testing;
