#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use SignalWire::Agent::AgentBase;
use SignalWire::Skills::SkillRegistry;

my $factory = SignalWire::Skills::SkillRegistry->get_factory('play_background_file');
ok(defined $factory, 'factory found');

subtest 'construction' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'pbg');
    my $skill = $factory->new(agent => $agent, params => {});
    is($skill->skill_name, 'play_background_file', 'skill_name');
    ok($skill->supports_multiple_instances, 'multi-instance');
};

subtest 'registers DataMap tool with files' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'pbg_reg');
    my $skill = $factory->new(agent => $agent, params => {
        files => [
            { key => 'music', description => 'Music', url => 'http://x.com/music.mp3' },
            { key => 'hold',  description => 'Hold',  url => 'http://x.com/hold.mp3' },
        ],
    });
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{play_background_file}, 'tool registered');
    my $func = $agent->tools->{play_background_file};
    ok(exists $func->{data_map}, 'has data_map');
    my $enum = $func->{parameters}{properties}{action}{enum};
    ok(grep({ $_ eq 'stop' } @$enum), 'has stop action');
    ok(grep({ $_ eq 'start_music' } @$enum), 'has start_music');
    ok(grep({ $_ eq 'start_hold' } @$enum), 'has start_hold');
};

subtest 'custom tool_name' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'pbg_custom');
    my $skill = $factory->new(agent => $agent, params => {
        tool_name => 'bg_player',
        files     => [],
    });
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{bg_player}, 'custom name');
};

subtest 'parameter schema' => sub {
    my $schema = $factory->get_parameter_schema;
    ok(exists $schema->{files}, 'has files');
    ok(exists $schema->{tool_name}, 'has tool_name');
};

done_testing;
