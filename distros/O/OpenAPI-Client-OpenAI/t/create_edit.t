#!perl

use lib 't/lib';
use OpenAITests;

my @test_cases = (
    {
        method      => 'createCompletion',
        description => 'Use an intruct model to correct spelling errors',
        params      => {
            model       => 'gpt-3.5-turbo-instruct',
            prompt      => "Correct the spelling errors in the following text:\n\nWat day of the wek is it?",
            temperature => 0,
        },
        expected_response => re('What day of the week is it\?'),
        against           => sub ($response) { $response->{choices}[0]{text} },
    },
);

run_test_cases( \@test_cases );

done_testing();
