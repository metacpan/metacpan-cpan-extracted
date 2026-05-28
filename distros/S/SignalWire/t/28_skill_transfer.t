#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use SignalWire::Agent::AgentBase;
use SignalWire::Skills::SkillRegistry;

my $factory = SignalWire::Skills::SkillRegistry->get_factory('swml_transfer');
ok(defined $factory, 'factory found');

subtest 'construction' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'tr');
    my $skill = $factory->new(agent => $agent, params => {});
    is($skill->skill_name, 'swml_transfer', 'skill_name');
    ok($skill->supports_multiple_instances, 'multi-instance');
};

subtest 'registers DataMap expressions' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'tr_reg');
    my $skill = $factory->new(agent => $agent, params => {
        transfers => {
            sales   => { url => 'https://example.com/sales', message => 'To sales' },
            support => { url => 'https://example.com/support' },
        },
    });
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{transfer_call}, 'transfer_call registered');
    my $dm = $agent->tools->{transfer_call}{data_map};
    ok(exists $dm->{expressions}, 'has expressions');
    is(scalar @{$dm->{expressions}}, 2, 'two expressions');
};

subtest 'custom tool and parameter names' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'tr_custom');
    my $skill = $factory->new(agent => $agent, params => {
        tool_name      => 'route_call',
        parameter_name => 'destination',
        transfers      => { sales => { url => 'http://x.com' } },
    });
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{route_call}, 'custom tool name');
    ok(exists $agent->tools->{route_call}{parameters}{properties}{destination}, 'custom param name');
};

subtest 'hints include transfer patterns' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'tr_hints');
    my $skill = $factory->new(agent => $agent, params => {
        transfers => { sales => { url => 'http://x.com' } },
    });
    my $hints = $skill->get_hints;
    ok(grep({ $_ eq 'transfer' } @$hints), 'includes transfer');
    ok(grep({ $_ eq 'sales' } @$hints), 'includes pattern name');
};

subtest 'prompt sections' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'tr_ps');
    my $skill = $factory->new(agent => $agent, params => {
        transfers => { sales => { url => 'http://x.com' } },
    });
    my $sections = $skill->get_prompt_sections;
    is(scalar @$sections, 2, 'two sections');
    is($sections->[0]{title}, 'Transferring', 'first title');
};

done_testing;
