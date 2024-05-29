#!perl

use lib 't/lib';
use OpenAITests;

my @test_cases = (
    {
        method      => 'createCompletion',
        description => 'createCompletion with an instruct model',
        params      => {
            model       => 'gpt-3.5-turbo-instruct',
            prompt      => 'What is the capital of France?',
            max_tokens  => 100,
            temperature => 0,
        },
        expected_response => re('\bParis\b'),
        against           => sub ($response) { $response->{choices}[0]{text} },
    },
    {
        method      => 'createCompletion',
        description => 'createCompletion with an instruct model, using `stop`',
        params      => {
            model       => 'gpt-3.5-turbo-instruct',
            prompt      => 'What is the capital of France?',
            max_tokens  => 100,
            temperature => 0,
            stop        => 'aris',
        },
        expected_response => re('P$'),
        against           => sub ($response) { $response->{choices}[0]{text} },
    },
    {
        method      => 'createCompletion',
        description => 'createCompletion with an instruct model, using multiple `stop`s',
        params      => {
            model       => 'gpt-3.5-turbo-instruct',
            prompt      => 'What is the capital of France?',
            max_tokens  => 100,
            temperature => 0,
            stop        => [ 'aris', 'xxx' ],
        },
        expected_response => re('P$'),
        against           => sub ($response) { $response->{choices}[0]{text} },
    },
);

run_test_cases( \@test_cases );

done_testing();
