#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use SignalWire::Agent::AgentBase;
use SignalWire::Skills::SkillRegistry;

my $factory = SignalWire::Skills::SkillRegistry->get_factory('weather_api');
ok(defined $factory, 'factory found');

subtest 'construction' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'w');
    my $skill = $factory->new(agent => $agent, params => {});
    is($skill->skill_name, 'weather_api', 'skill_name');
};

subtest 'registers DataMap tool' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'w_reg');
    my $skill = $factory->new(agent => $agent, params => { api_key => 'test' });
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{get_weather}, 'get_weather registered');
    ok(exists $agent->tools->{get_weather}{data_map}, 'has data_map');
};

subtest 'custom tool_name' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'w_custom');
    my $skill = $factory->new(agent => $agent, params => { tool_name => 'my_weather', api_key => 'k' });
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{my_weather}, 'custom tool name');
    ok(!exists $agent->tools->{get_weather}, 'default not used');
};

subtest 'celsius unit' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'w_c');
    my $skill = $factory->new(agent => $agent, params => { api_key => 'k', temperature_unit => 'celsius' });
    $skill->setup;
    $skill->register_tools;
    my $output = $agent->tools->{get_weather}{data_map}{webhooks}[0]{output}{response};
    like($output, qr/temp_c/, 'uses celsius field');
};

subtest 'parameter schema' => sub {
    my $schema = $factory->get_parameter_schema;
    ok(exists $schema->{api_key}, 'has api_key');
    ok(exists $schema->{temperature_unit}, 'has temperature_unit');
    is_deeply($schema->{temperature_unit}{enum}, ['fahrenheit', 'celsius'], 'enum values');
};

done_testing;
