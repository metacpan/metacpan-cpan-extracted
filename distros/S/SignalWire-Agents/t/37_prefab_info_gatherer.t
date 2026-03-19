#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use JSON qw(encode_json decode_json);

use_ok('SignalWire::Agents::Prefabs::InfoGatherer');

subtest 'construction defaults' => sub {
    my $a = SignalWire::Agents::Prefabs::InfoGatherer->new(
        questions => [
            { key_name => 'name', question_text => 'What is your name?' },
            { key_name => 'email', question_text => 'What is your email?', confirm => 1 },
        ],
    );
    is($a->name, 'info_gatherer', 'default name');
    is($a->route, '/info_gatherer', 'default route');
    ok($a->isa('SignalWire::Agents::Agent::AgentBase'), 'isa AgentBase');
};

subtest 'tools registered' => sub {
    my $a = SignalWire::Agents::Prefabs::InfoGatherer->new(
        questions => [{ key_name => 'n', question_text => 'N?' }],
    );
    ok(exists $a->tools->{start_questions}, 'start_questions');
    ok(exists $a->tools->{submit_answer}, 'submit_answer');
};

subtest 'prompt section' => sub {
    my $a = SignalWire::Agents::Prefabs::InfoGatherer->new(
        questions => [{ key_name => 'n', question_text => 'N?' }],
    );
    ok($a->prompt_has_section('Information Gathering'), 'has section');
};

subtest 'global data' => sub {
    my $a = SignalWire::Agents::Prefabs::InfoGatherer->new(
        questions => [
            { key_name => 'n', question_text => 'Name?' },
            { key_name => 'e', question_text => 'Email?' },
        ],
    );
    my $gdata = $a->global_data;
    is(scalar @{$gdata->{questions}}, 2, 'two questions');
    is($gdata->{question_index}, 0, 'index starts 0');
    is_deeply($gdata->{answers}, [], 'empty answers');
};

subtest 'tool execution' => sub {
    my $a = SignalWire::Agents::Prefabs::InfoGatherer->new(
        questions => [{ key_name => 'name', question_text => 'What is your name?' }],
    );
    my $start = $a->on_function_call('start_questions', {}, {});
    ok(defined $start, 'start_questions returns result');
    like($start->response, qr/name/, 'returns first question');

    my $answer = $a->on_function_call('submit_answer', { answer => 'John' }, {});
    ok(defined $answer, 'submit_answer returns result');
    like($answer->response, qr/John/, 'response includes answer');
};

subtest 'render_swml' => sub {
    my $a = SignalWire::Agents::Prefabs::InfoGatherer->new(
        questions => [{ key_name => 'n', question_text => 'N?' }],
    );
    my $swml = $a->render_swml;
    is($swml->{version}, '1.0.0', 'version');
    my @ai = grep { exists $_->{ai} } @{$swml->{sections}{main}};
    ok(scalar @ai >= 1, 'AI verb present');
    ok(exists $ai[0]{ai}{SWAIG}{functions}, 'functions present');
};

subtest 'custom name and route' => sub {
    my $a = SignalWire::Agents::Prefabs::InfoGatherer->new(
        name      => 'intake',
        route     => '/intake',
        questions => [{ key_name => 'n', question_text => 'N?' }],
    );
    is($a->name, 'intake', 'custom name');
    is($a->route, '/intake', 'custom route');
};

subtest 'psgi_app' => sub {
    my $a = SignalWire::Agents::Prefabs::InfoGatherer->new(
        questions => [{ key_name => 'n', question_text => 'N?' }],
    );
    my $app = $a->psgi_app;
    is(ref $app, 'CODE', 'psgi_app returns coderef');
};

done_testing;
