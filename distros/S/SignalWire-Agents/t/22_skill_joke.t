#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON ();

use SignalWire::Agents::Agent::AgentBase;
use SignalWire::Agents::Skills::SkillRegistry;

my $factory = SignalWire::Agents::Skills::SkillRegistry->get_factory('joke');
ok(defined $factory, 'factory found');

subtest 'construction' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'joke');
    my $skill = $factory->new(agent => $agent, params => {});
    is($skill->skill_name, 'joke', 'skill_name');
};

subtest 'registers DataMap tool' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'joke_dm');
    my $skill = $factory->new(agent => $agent, params => { api_key => 'test-key' });
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{get_joke}, 'get_joke registered');
    ok(exists $agent->tools->{get_joke}{data_map}, 'has data_map');
    is($agent->tools->{get_joke}{data_map}{webhooks}[0]{method}, 'GET', 'webhook method');
};

subtest 'custom tool_name' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'joke_custom');
    my $skill = $factory->new(agent => $agent, params => { tool_name => 'tell_joke' });
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{tell_joke}, 'custom tool name');
    ok(!exists $agent->tools->{get_joke}, 'default name not used');
};

subtest 'global data' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'joke_gd');
    my $skill = $factory->new(agent => $agent, params => {});
    my $gdata = $skill->get_global_data;
    ok(exists $gdata->{joke_skill_enabled}, 'joke_skill_enabled');
};

subtest 'prompt sections' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'joke_ps');
    my $skill = $factory->new(agent => $agent, params => {});
    my $sections = $skill->get_prompt_sections;
    is($sections->[0]{title}, 'Joke Telling', 'title');
};

subtest 'parameter schema' => sub {
    my $schema = $factory->get_parameter_schema;
    ok(exists $schema->{api_key}, 'has api_key');
    ok(exists $schema->{tool_name}, 'has tool_name');
};

done_testing;
