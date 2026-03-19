#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use SignalWire::Agents::Agent::AgentBase;
use SignalWire::Agents::Skills::SkillRegistry;

my $factory = SignalWire::Agents::Skills::SkillRegistry->get_factory('math');
ok(defined $factory, 'factory found');

subtest 'construction and registration' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'math');
    my $skill = $factory->new(agent => $agent, params => {});
    is($skill->skill_name, 'math', 'skill_name');
    ok($skill->setup, 'setup');
    $skill->register_tools;
    ok(exists $agent->tools->{calculate}, 'calculate tool registered');
};

subtest 'calculate valid expression' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'math_exec');
    my $skill = $factory->new(agent => $agent, params => {});
    $skill->setup;
    $skill->register_tools;
    my $result = $agent->on_function_call('calculate', { expression => '2 + 3' }, {});
    ok(defined $result, 'result defined');
    like($result->response, qr/5/, 'correct calculation');
};

subtest 'calculate invalid expression' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'math_bad');
    my $skill = $factory->new(agent => $agent, params => {});
    $skill->setup;
    $skill->register_tools;
    my $result = $agent->on_function_call('calculate', { expression => 'system("bad")' }, {});
    like($result->response, qr/Could not evaluate/, 'rejects unsafe expression');
};

subtest 'prompt sections' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'math_ps');
    my $skill = $factory->new(agent => $agent, params => {});
    my $sections = $skill->get_prompt_sections;
    ok(scalar @$sections > 0, 'has sections');
    is($sections->[0]{title}, 'Mathematical Calculations', 'title');
};

done_testing;
