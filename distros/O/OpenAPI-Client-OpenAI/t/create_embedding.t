#!perl

use lib 't/lib';
use OpenAITests;

my @test_cases = (
    {
        method      => 'createEmbedding',
        description => 'Create an embedding vector',
        params      => {
            model => 'text-embedding-ada-002',
            input => 'The food was delicious and the waiter...',
        },
        expected_response => noclass( {
            object => 'list',
            data   => [
                {
                    object    => 'embedding',
                    embedding => array_each( ignore() ),    # array of floats
                    index     => 0,
                },
            ],
            model => ignore(),
            usage => {
                prompt_tokens => ignore(),
                total_tokens  => ignore(),
            }
        } ),
        against => sub ($response) {$response},    # testing the entire response
    },
);

run_test_cases( \@test_cases );

done_testing();
