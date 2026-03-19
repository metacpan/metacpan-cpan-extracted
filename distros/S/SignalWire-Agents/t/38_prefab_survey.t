#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON qw(encode_json decode_json);

use_ok('SignalWire::Agents::Prefabs::Survey');

subtest 'construction defaults' => sub {
    my $a = SignalWire::Agents::Prefabs::Survey->new(
        survey_name      => 'Test Survey',
        survey_questions => [
            { id => 'q1', text => 'Rate us', type => 'rating', scale => 5, required => 1 },
        ],
    );
    is($a->name, 'survey', 'default name');
    is($a->route, '/survey', 'default route');
    ok($a->isa('SignalWire::Agents::Agent::AgentBase'), 'isa AgentBase');
};

subtest 'tools registered' => sub {
    my $a = SignalWire::Agents::Prefabs::Survey->new(
        survey_name      => 'S',
        survey_questions => [{ id => 'q1', text => 'Q?', type => 'rating', scale => 5, required => 1 }],
    );
    ok(exists $a->tools->{submit_survey_answer}, 'submit_survey_answer');
};

subtest 'prompt sections' => sub {
    my $a = SignalWire::Agents::Prefabs::Survey->new(
        survey_name      => 'Test',
        survey_questions => [{ id => 'q1', text => 'Q?', type => 'open_ended', required => 0 }],
    );
    ok($a->prompt_has_section('Survey Introduction'), 'intro section');
    ok($a->prompt_has_section('Survey Questions'), 'questions section');
};

subtest 'global data' => sub {
    my $a = SignalWire::Agents::Prefabs::Survey->new(
        survey_name      => 'Satisfaction',
        survey_questions => [
            { id => 'q1', text => 'Q1?', type => 'rating', scale => 5, required => 1 },
            { id => 'q2', text => 'Q2?', type => 'open_ended', required => 0 },
        ],
    );
    my $gdata = $a->global_data;
    is($gdata->{survey_name}, 'Satisfaction', 'survey name in data');
    is(scalar @{$gdata->{questions}}, 2, 'two questions');
};

subtest 'tool execution' => sub {
    my $a = SignalWire::Agents::Prefabs::Survey->new(
        survey_name      => 'S',
        survey_questions => [{ id => 'q1', text => 'Q?', type => 'rating', scale => 5, required => 1 }],
    );
    my $result = $a->on_function_call('submit_survey_answer', { question_id => 'q1', answer => '5' }, {});
    ok(defined $result, 'returns result');
    like($result->response, qr/q1/, 'response mentions question id');
};

subtest 'render_swml' => sub {
    my $a = SignalWire::Agents::Prefabs::Survey->new(
        survey_name      => 'S',
        survey_questions => [{ id => 'q1', text => 'Q?', type => 'rating', scale => 5, required => 1 }],
    );
    my $swml = $a->render_swml;
    is($swml->{version}, '1.0.0', 'version');
};

subtest 'custom introduction' => sub {
    my $a = SignalWire::Agents::Prefabs::Survey->new(
        survey_name      => 'S',
        survey_questions => [{ id => 'q1', text => 'Q?', type => 'rating', scale => 5, required => 1 }],
        introduction     => 'Welcome to our custom survey!',
    );
    # The prompt section body should contain the custom intro
    my $pom = $a->pom_sections;
    my ($intro_sec) = grep { $_->{title} eq 'Survey Introduction' } @$pom;
    like($intro_sec->{body}, qr/custom survey/, 'custom introduction in prompt');
};

done_testing;
