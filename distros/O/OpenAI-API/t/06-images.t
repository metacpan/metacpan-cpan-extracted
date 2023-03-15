#!perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::RequiresInternet;

use OpenAI::API;

if ( !$ENV{OPENAI_API_KEY} ) {
    plan skip_all => 'This test requires an OPENAI_API_KEY environment variable';
}

my $openai = OpenAI::API->new();

my @test_cases = (
    {
        method => 'image_create',
        params => {
            prompt => 'A cute baby sea otter',
            size   => '256x256',
            response_format => 'b64_json',
        },
        expected_response => {
            created => ignore(),
            data    => array_each(
                {
                    b64_json => ignore(),
                }
            ),
        },
    },

);

for my $test (@test_cases) {
    my ( $method, $params, $expected_response ) = @{$test}{qw/method params expected_response/};

    my $response = $openai->$method( %{$params} );
    cmp_deeply( $response, $expected_response );
}

done_testing();
