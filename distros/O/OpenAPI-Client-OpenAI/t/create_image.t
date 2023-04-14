#!perl

use strict;
use warnings;

use Data::Dumper;
use JSON;

use Test::More;
use Test::Deep;
use Test::RequiresInternet;

use OpenAPI::Client::OpenAI;

if ( !$ENV{OPENAI_API_KEY} ) {
    plan skip_all => 'This test requires an OPENAI_API_KEY environment variable';
}

my $openai = OpenAPI::Client::OpenAI->new();

my @test_cases = (
    {
        method => 'createImage',
        params => {
            prompt          => 'A cute baby sea otter',
            size            => '256x256',
            response_format => 'b64_json',
        },
        expected_response => noclass(
            {
                created => ignore(),
                data    => array_each(
                    {
                        b64_json => ignore(),
                    }
                ),
            }
        ),
    },

);

for my $test (@test_cases) {
    my ( $method, $params, $expected_response ) = @{$test}{qw/method params expected_response/};

    my $tx = $openai->$method( { body => $params } );

    my $response = $tx->res->json;

    cmp_deeply( $response, $expected_response )
        or diag( Dumper $response );
}

done_testing();
