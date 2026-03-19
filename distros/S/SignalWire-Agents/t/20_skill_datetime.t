#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use SignalWire::Agents::Agent::AgentBase;
use SignalWire::Agents::Skills::SkillRegistry;

my $factory = SignalWire::Agents::Skills::SkillRegistry->get_factory('datetime');
ok(defined $factory, 'factory found');
is($factory, 'SignalWire::Agents::Skills::Builtin::Datetime', 'correct class');

subtest 'construction' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'dt');
    my $skill = $factory->new(agent => $agent, params => {});
    is($skill->skill_name, 'datetime', 'skill_name');
    is($skill->skill_version, '1.0.0', 'version');
    ok(!$skill->supports_multiple_instances, 'no multi-instance');
};

subtest 'setup and register_tools' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'dt_reg');
    my $skill = $factory->new(agent => $agent, params => {});
    ok($skill->setup, 'setup');
    $skill->register_tools;
    ok(exists $agent->tools->{get_current_time}, 'get_current_time registered');
    ok(exists $agent->tools->{get_current_date}, 'get_current_date registered');
};

subtest 'tool execution' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'dt_exec');
    my $skill = $factory->new(agent => $agent, params => {});
    $skill->setup;
    $skill->register_tools;
    my $result = $agent->on_function_call('get_current_time', { timezone => 'UTC' }, {});
    ok(defined $result, 'handler returns result');
    like($result->response, qr/current time/, 'response mentions time');
};

subtest 'prompt sections' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'dt_ps');
    my $skill = $factory->new(agent => $agent, params => {});
    my $sections = $skill->get_prompt_sections;
    ok(scalar @$sections > 0, 'has prompt sections');
    is($sections->[0]{title}, 'Date and Time Information', 'title');
};

subtest 'skip_prompt' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'dt_skip');
    my $skill = $factory->new(agent => $agent, params => { skip_prompt => 1 });
    my $sections = $skill->get_prompt_sections;
    is(scalar @$sections, 0, 'no sections when skip_prompt');
};

subtest 'parameter_schema' => sub {
    my $schema = $factory->get_parameter_schema;
    ok(exists $schema->{swaig_fields}, 'has swaig_fields');
    ok(exists $schema->{skip_prompt}, 'has skip_prompt');
};

done_testing;
