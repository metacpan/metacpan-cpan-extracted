#!perl

use lib 't/lib';
use OpenAITests;

my @test_cases = (
    {
        method      => 'createImage',
        description => 'Test creating an image',
        params      => {
            model   => 'gpt-image-1-mini',
            prompt  => 'A cute baby sea otter',
            size    => '1024x1024',
            quality => 'low',
        },
        expected_response => noclass( superhashof( {
            created => ignore(),
            data    => array_each( superhashof( {
                b64_json => ignore(),
            } ) ),
        } ) ),
        against => sub ($response) {$response},    # testing the entire response
    },

);

run_test_cases( \@test_cases );

done_testing();
