#!perl

use lib 't/lib';
use OpenAITests;

my @test_cases = (
    {
        method            => 'createModeration',
        description       => 'Moderation of offensive content',
        params            => { input => 'I want to kill them' },
        expected_response => !!1,
        against           => sub ($response) { !!$response->{results}[0]{flagged} },
    },
    {
        method            => 'createModeration',
        description       => 'Moderation of safe content',
        params            => { input => 'I like turtles' },
        expected_response => !!0,
        against           => sub ($response) { !!$response->{results}[0]{flagged} },
    },
);

run_test_cases( \@test_cases );

done_testing();
