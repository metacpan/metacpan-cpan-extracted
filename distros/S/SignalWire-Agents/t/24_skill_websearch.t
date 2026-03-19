#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use SignalWire::Agents::Agent::AgentBase;
use SignalWire::Agents::Skills::SkillRegistry;

my $factory = SignalWire::Agents::Skills::SkillRegistry->get_factory('web_search');
ok(defined $factory, 'factory found');

subtest 'construction' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'ws');
    my $skill = $factory->new(agent => $agent, params => {});
    is($skill->skill_name, 'web_search', 'skill_name');
    is($skill->skill_version, '2.0.0', 'version 2.0.0');
    ok($skill->supports_multiple_instances, 'supports multi-instance');
};

subtest 'registers tool' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'ws_reg');
    my $skill = $factory->new(agent => $agent, params => {});
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{web_search}, 'web_search registered');
};

subtest 'custom tool_name' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'ws_custom');
    my $skill = $factory->new(agent => $agent, params => { tool_name => 'search' });
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{search}, 'custom tool name');
};

subtest 'global data' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'ws_gd');
    my $skill = $factory->new(agent => $agent, params => {});
    my $gdata = $skill->get_global_data;
    ok(exists $gdata->{web_search_enabled}, 'web_search_enabled');
    ok(exists $gdata->{quality_filtering}, 'quality_filtering');
};

subtest 'prompt sections' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'ws_ps');
    my $skill = $factory->new(agent => $agent, params => {});
    my $sections = $skill->get_prompt_sections;
    like($sections->[0]{title}, qr/Web Search/, 'title');
};

subtest 'parameter schema' => sub {
    my $schema = $factory->get_parameter_schema;
    ok(exists $schema->{api_key}, 'has api_key');
    ok(exists $schema->{search_engine_id}, 'has search_engine_id');
    ok(exists $schema->{num_results}, 'has num_results');
};

done_testing;
