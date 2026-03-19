#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('SignalWire::Agents::Prefabs::FAQBot');

subtest 'construction defaults' => sub {
    my $a = SignalWire::Agents::Prefabs::FAQBot->new(
        faqs => [
            { question => 'What is SignalWire?', answer => 'A cloud comms platform.' },
        ],
    );
    is($a->name, 'faq_bot', 'default name');
    is($a->route, '/faq', 'default route');
    ok($a->isa('SignalWire::Agents::Agent::AgentBase'), 'isa AgentBase');
};

subtest 'tools registered' => sub {
    my $a = SignalWire::Agents::Prefabs::FAQBot->new(
        faqs => [{ question => 'Q?', answer => 'A.' }],
    );
    ok(exists $a->tools->{lookup_faq}, 'lookup_faq tool');
};

subtest 'prompt sections' => sub {
    my $a = SignalWire::Agents::Prefabs::FAQBot->new(
        faqs => [{ question => 'Q?', answer => 'A.' }],
    );
    ok($a->prompt_has_section('Personality'), 'personality');
    ok($a->prompt_has_section('FAQ Knowledge Base'), 'faq knowledge');
};

subtest 'suggest_related section' => sub {
    my $a = SignalWire::Agents::Prefabs::FAQBot->new(
        faqs           => [{ question => 'Q?', answer => 'A.' }],
        suggest_related => 1,
    );
    ok($a->prompt_has_section('Related Questions'), 'related questions section');
};

subtest 'suggest_related disabled' => sub {
    my $a = SignalWire::Agents::Prefabs::FAQBot->new(
        faqs           => [{ question => 'Q?', answer => 'A.' }],
        suggest_related => 0,
    );
    ok(!$a->prompt_has_section('Related Questions'), 'no related questions section');
};

subtest 'lookup_faq - found' => sub {
    my $a = SignalWire::Agents::Prefabs::FAQBot->new(
        faqs => [{ question => 'What is SignalWire?', answer => 'Cloud comms.' }],
    );
    my $result = $a->on_function_call('lookup_faq', { query => 'signalwire' }, {});
    ok(defined $result, 'returns result');
    like($result->response, qr/Cloud comms/, 'found answer');
};

subtest 'lookup_faq - not found' => sub {
    my $a = SignalWire::Agents::Prefabs::FAQBot->new(
        faqs => [{ question => 'What is SignalWire?', answer => 'Cloud comms.' }],
    );
    my $result = $a->on_function_call('lookup_faq', { query => 'xyznonexistent' }, {});
    ok(defined $result, 'returns result');
    like($result->response, qr/No FAQ found/i, 'not found message');
};

subtest 'custom name/route' => sub {
    my $a = SignalWire::Agents::Prefabs::FAQBot->new(
        name  => 'my_faq',
        route => '/my_faq',
        faqs  => [{ question => 'Q?', answer => 'A.' }],
    );
    is($a->name, 'my_faq', 'custom name');
    is($a->route, '/my_faq', 'custom route');
};

subtest 'global data' => sub {
    my $a = SignalWire::Agents::Prefabs::FAQBot->new(
        faqs => [
            { question => 'Q1?', answer => 'A1.' },
            { question => 'Q2?', answer => 'A2.' },
        ],
    );
    is(scalar @{$a->global_data->{faqs}}, 2, 'two FAQs in global data');
};

done_testing;
