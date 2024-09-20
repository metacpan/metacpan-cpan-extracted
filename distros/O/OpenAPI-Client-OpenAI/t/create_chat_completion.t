#!perl

use lib 't/lib';
use OpenAITests;

my @test_cases = (
    {
        method      => 'createChatCompletion',
        description => 'Standard chat completion for "Hello!"',
        params      => {
            model       => 'gpt-3.5-turbo',
            messages    => [ { "role" => "user", "content" => "Hello!" }, ],
            max_tokens  => 100,
            temperature => 0,
        },
        expected_response => {
            role    => 'assistant',
            content => re('\b(?:Hello|Hi|Hey)\b'),
            refusal => undef,
        },
    },
    {
        method      => 'createChatCompletion',
        description => 'Standard chat completion, but with `stop` added to halt token generation',
        params      => {
            model       => 'gpt-3.5-turbo',
            messages    => [ { "role" => "user", "content" => "Hello!" }, ],
            max_tokens  => 100,
            temperature => 0,
            stop        => [ 'Hello', 'Hi', 'Hey' ],
        },
        expected_response => {
            role    => 'assistant',
            content => re('^\s*$'),
            refusal => undef,
        },
    },
);

run_test_cases( \@test_cases );

done_testing();
