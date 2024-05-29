#!perl

use lib 't/lib';
use OpenAITests;

my @test_cases = (
    {
        method      => 'createImage',
        description => 'Test creating an image',
        params      => {
            prompt          => 'A cute baby sea otter',
            size            => '256x256',
            response_format => 'b64_json',
        },
        expected_response => noclass( {
            created => ignore(),
            data    => array_each( {
                b64_json => ignore(),
            } ),
        } ),
        against => sub ($response) {$response},    # testing the entire response
    },

);

run_test_cases( \@test_cases );

done_testing();
