#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use SignalWire::Agent::AgentBase;
use SignalWire::Skills::SkillRegistry;

my $factory = SignalWire::Skills::SkillRegistry->get_factory('web_search');
ok(defined $factory, 'factory found');

subtest 'construction' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'ws');
    my $skill = $factory->new(agent => $agent, params => {});
    is($skill->skill_name, 'web_search', 'skill_name');
    is($skill->skill_version, '2.0.0', 'version 2.0.0');
    ok($skill->supports_multiple_instances, 'supports multi-instance');
};

subtest 'registers tool' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'ws_reg');
    my $skill = $factory->new(agent => $agent, params => {});
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{web_search}, 'web_search registered');
};

subtest 'custom tool_name' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'ws_custom');
    my $skill = $factory->new(agent => $agent, params => { tool_name => 'search' });
    $skill->setup;
    $skill->register_tools;
    ok(exists $agent->tools->{search}, 'custom tool name');
};

subtest 'global data' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'ws_gd');
    my $skill = $factory->new(agent => $agent, params => {});
    my $gdata = $skill->get_global_data;
    ok(exists $gdata->{web_search_enabled}, 'web_search_enabled');
    ok(exists $gdata->{quality_filtering}, 'quality_filtering');
};

subtest 'prompt sections' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'ws_ps');
    my $skill = $factory->new(agent => $agent, params => {});
    my $sections = $skill->get_prompt_sections;
    like($sections->[0]{title}, qr/Web Search/, 'title');
};

subtest 'parameter schema' => sub {
    my $schema = $factory->get_parameter_schema;
    ok(exists $schema->{api_key}, 'has api_key');
    ok(exists $schema->{search_engine_id}, 'has search_engine_id');
    ok(exists $schema->{num_results}, 'has num_results');
    ok(exists $schema->{response_prefix},  'has response_prefix');
    ok(exists $schema->{response_postfix}, 'has response_postfix');
};

# ----------------------------------------------------------------
# Python 8aad242 parity: response_prefix / response_postfix wrap
# successful results, leave error / empty branches alone.
# ----------------------------------------------------------------
subtest 'response_prefix wraps success body' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'ws_prefix');
    my $skill = $factory->new(agent => $agent,
                              params => { response_prefix => 'BEGIN-CITATION' });
    my $out = $skill->_wrap_response("1. Foo\n   Foo snippet\n   http://x");
    like($out, qr/\ABEGIN-CITATION\n\n1\. Foo\b/,
         'prefix prepended with blank-line separator');
};

subtest 'response_postfix wraps success body' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'ws_postfix');
    my $skill = $factory->new(agent => $agent,
                              params => { response_postfix => 'END-CITATION' });
    my $out = $skill->_wrap_response("1. Foo\n   snippet\n   http://x");
    like($out, qr/http:\/\/x\n\nEND-CITATION\z/,
         'postfix appended with blank-line separator');
};

subtest 'both prefix and postfix wrap success body' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'ws_both');
    my $skill = $factory->new(agent => $agent, params => {
        response_prefix  => 'P',
        response_postfix => 'Q',
    });
    my $out = $skill->_wrap_response("body");
    is($out, "P\n\nbody\n\nQ",
       'both wrappers applied in canonical order');
};

subtest 'no wrap when neither prefix nor postfix set' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'ws_no_wrap');
    my $skill = $factory->new(agent => $agent, params => {});
    my $body = "1. Foo\n   snippet\n   http://x";
    is($skill->_wrap_response($body), $body,
       'response passed through unchanged when params absent');
};

subtest 'error responses are NOT wrapped' => sub {
    my $agent = SignalWire::Agent::AgentBase->new(name => 'ws_err');
    my $skill = $factory->new(agent => $agent, params => {
        response_prefix  => 'WRAP',
        response_postfix => 'WRAP',
    });
    is($skill->_wrap_response('Web search error: 503 Service Unavailable'),
       'Web search error: 503 Service Unavailable',
       'HTTP error passes through unwrapped (matches Python)');
    is($skill->_wrap_response('Web search parse error: bad json'),
       'Web search parse error: bad json',
       'parse error passes through unwrapped');
    is($skill->_wrap_response('No results for: zzz'),
       'No results for: zzz',
       'empty-result sentinel passes through unwrapped');
};

done_testing;
