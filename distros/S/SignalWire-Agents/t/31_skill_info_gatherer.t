#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use SignalWire::Agents::Agent::AgentBase;
use SignalWire::Agents::Skills::SkillRegistry;

my $factory = SignalWire::Agents::Skills::SkillRegistry->get_factory('info_gatherer');
ok(defined $factory, 'factory found');

subtest 'construction' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'ig');
    my $skill = $factory->new(agent => $agent, params => {});
    is($skill->skill_name, 'info_gatherer', 'skill_name');
    ok($skill->supports_multiple_instances, 'multi-instance');
};

subtest 'registers tools' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'ig_reg');
    my $skill = $factory->new(agent => $agent, params => {
        questions => [{ key_name => 'name', question_text => 'Your name?' }],
    });
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{start_questions}, 'start_questions');
    ok(exists $agent->tools->{submit_answer}, 'submit_answer');
};

subtest 'prefix option' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'ig_prefix');
    my $skill = $factory->new(agent => $agent, params => {
        prefix    => 'intake',
        questions => [{ key_name => 'x', question_text => 'Q?' }],
    });
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{intake_start_questions}, 'prefixed start');
    ok(exists $agent->tools->{intake_submit_answer}, 'prefixed submit');
};

subtest 'global data' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'ig_gd');
    my $skill = $factory->new(agent => $agent, params => {
        questions => [{ key_name => 'n', question_text => 'Name?' }],
    });
    my $gdata = $skill->get_global_data;
    my $ns = $gdata->{info_gatherer};
    ok(defined $ns, 'namespace exists');
    is(scalar @{$ns->{questions}}, 1, 'one question');
    is($ns->{question_index}, 0, 'index starts at 0');
};

subtest 'prompt sections' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'ig_ps');
    my $skill = $factory->new(agent => $agent, params => {});
    my $sections = $skill->get_prompt_sections;
    ok(scalar @$sections > 0, 'has sections');
    like($sections->[0]{title}, qr/Info Gatherer/, 'title');
};

subtest 'parameter schema' => sub {
    my $schema = $factory->get_parameter_schema;
    ok(exists $schema->{questions}, 'has questions');
    ok(exists $schema->{prefix}, 'has prefix');
};

done_testing;
