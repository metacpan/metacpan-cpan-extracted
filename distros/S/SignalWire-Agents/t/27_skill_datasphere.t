#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON ();

use SignalWire::Agents::Agent::AgentBase;
use SignalWire::Agents::Skills::SkillRegistry;

my $factory = SignalWire::Agents::Skills::SkillRegistry->get_factory('datasphere');
ok(defined $factory, 'factory found');

subtest 'construction' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'ds');
    my $skill = $factory->new(agent => $agent, params => {});
    is($skill->skill_name, 'datasphere', 'skill_name');
    ok($skill->supports_multiple_instances, 'multi-instance');
};

subtest 'registers tool' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'ds_reg');
    my $skill = $factory->new(agent => $agent, params => {});
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{search_knowledge}, 'search_knowledge registered');
};

subtest 'custom tool_name' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'ds_custom');
    my $skill = $factory->new(agent => $agent, params => { tool_name => 'my_search' });
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{my_search}, 'custom name');
};

subtest 'global data' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'ds_gd');
    my $skill = $factory->new(agent => $agent, params => { document_id => 'doc123' });
    my $gdata = $skill->get_global_data;
    ok(exists $gdata->{datasphere_enabled}, 'datasphere_enabled');
    is($gdata->{document_id}, 'doc123', 'document_id');
};

subtest 'prompt sections' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'ds_ps');
    my $skill = $factory->new(agent => $agent, params => {});
    my $sections = $skill->get_prompt_sections;
    like($sections->[0]{title}, qr/Knowledge Search/, 'title');
};

subtest 'parameter schema' => sub {
    my $schema = $factory->get_parameter_schema;
    ok(exists $schema->{space_name}, 'has space_name');
    ok(exists $schema->{document_id}, 'has document_id');
    ok(exists $schema->{distance}, 'has distance');
};

done_testing;
