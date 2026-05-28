#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use SignalWire::Agent::AgentBase;
use SignalWire::Skills::SkillRegistry;

my $factory = SignalWire::Skills::SkillRegistry->get_factory('claude_skills');
ok(defined $factory, 'factory found');

subtest 'construction' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'cs');
    my $skill = $factory->new(agent => $agent, params => {});
    is($skill->skill_name, 'claude_skills', 'skill_name');
    ok($skill->supports_multiple_instances, 'multi-instance');
};

subtest 'registers stub tool' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'cs_reg');
    my $skill = $factory->new(agent => $agent, params => {});
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{claude_skill}, 'claude_skill registered');
};

subtest 'custom prefix' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'cs_prefix');
    my $skill = $factory->new(agent => $agent, params => { tool_prefix => 'my_' });
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{my_skill}, 'custom prefix tool name');
};

subtest 'hints' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'cs_hints');
    my $skill = $factory->new(agent => $agent, params => {});
    my $hints = $skill->get_hints;
    ok(grep({ $_ eq 'claude' } @$hints), 'claude hint');
};

subtest 'parameter schema' => sub {
    my $schema = $factory->get_parameter_schema;
    ok(exists $schema->{skills_path}, 'has skills_path');
    ok(exists $schema->{tool_prefix}, 'has tool_prefix');
};

done_testing;
