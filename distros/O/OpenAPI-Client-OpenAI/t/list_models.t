#!perl

use lib 't/lib';
use OpenAITests;

my @test_cases = (
    {
        method            => 'listModels',
        description       => 'List all models available, if any',
        params            => {},
        expected_response => noclass( superhashof( {
            object => 'list',
            data   => array_each( superhashof( {
                id       => ignore(),    # e.g. ada, babbage, etc.
                object   => 'model',
                owned_by => ignore(),
            } ) ),
        } ) ),
        against => sub ($response) {$response},
    },
);

run_test_cases( \@test_cases );

done_testing();
