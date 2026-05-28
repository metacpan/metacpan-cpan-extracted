#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use SignalWire::Agent::AgentBase;
use SignalWire::Skills::SkillRegistry;

my $factory = SignalWire::Skills::SkillRegistry->get_factory('wikipedia_search');
ok(defined $factory, 'factory found');

subtest 'construction' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'wiki');
    my $skill = $factory->new(agent => $agent, params => {});
    is($skill->skill_name, 'wikipedia_search', 'skill_name');
    ok(!$skill->supports_multiple_instances, 'no multi-instance');
};

subtest 'registers tool' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'wiki_reg');
    my $skill = $factory->new(agent => $agent, params => {});
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{search_wiki}, 'search_wiki registered');
};

subtest 'tool execution' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'wiki_exec');
    my $skill = $factory->new(agent => $agent, params => {});
    $skill->setup;
    $skill->register_tools;
    my $result = $agent->on_function_call('search_wiki', { query => 'Perl' }, {});
    ok(defined $result, 'returns result');
    like($result->response, qr/Perl/, 'response mentions query');
};

subtest 'prompt sections' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'wiki_ps');
    my $skill = $factory->new(agent => $agent, params => {});
    my $sections = $skill->get_prompt_sections;
    is($sections->[0]{title}, 'Wikipedia Search', 'title');
};

subtest 'parameter schema' => sub {
    my $schema = $factory->get_parameter_schema;
    ok(exists $schema->{num_results}, 'has num_results');
};

done_testing;
