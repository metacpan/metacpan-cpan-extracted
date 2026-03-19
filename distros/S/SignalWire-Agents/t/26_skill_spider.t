#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use SignalWire::Agents::Agent::AgentBase;
use SignalWire::Agents::Skills::SkillRegistry;

my $factory = SignalWire::Agents::Skills::SkillRegistry->get_factory('spider');
ok(defined $factory, 'factory found');

subtest 'construction' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'sp');
    my $skill = $factory->new(agent => $agent, params => {});
    is($skill->skill_name, 'spider', 'skill_name');
    ok($skill->supports_multiple_instances, 'multi-instance');
};

subtest 'registers 3 tools' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'sp_reg');
    my $skill = $factory->new(agent => $agent, params => {});
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{scrape_url}, 'scrape_url');
    ok(exists $agent->tools->{crawl_site}, 'crawl_site');
    ok(exists $agent->tools->{extract_structured_data}, 'extract_structured_data');
};

subtest 'hints' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'sp_hints');
    my $skill = $factory->new(agent => $agent, params => {});
    my $hints = $skill->get_hints;
    ok(scalar @$hints > 0, 'has hints');
    ok(grep({ $_ eq 'spider' } @$hints), 'includes spider');
    ok(grep({ $_ eq 'scrape' } @$hints), 'includes scrape');
};

subtest 'tool execution' => sub {
    my $agent = SignalWire::Agents::Agent::AgentBase->new(name => 'sp_exec');
    my $skill = $factory->new(agent => $agent, params => {});
    $skill->setup;
    $skill->register_tools;
    my $result = $agent->on_function_call('scrape_url', { url => 'https://example.com' }, {});
    ok(defined $result, 'scrape returns result');
    like($result->response, qr/example\.com/, 'mentions URL');
};

subtest 'parameter schema' => sub {
    my $schema = $factory->get_parameter_schema;
    ok(exists $schema->{max_pages}, 'has max_pages');
    ok(exists $schema->{timeout}, 'has timeout');
};

done_testing;
