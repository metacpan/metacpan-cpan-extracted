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
        method => 'embeddings',
        params => {
            model => 'text-embedding-ada-002',
            input => 'The food was delicious and the waiter...',
        },
        expected_response => noclass(
            {
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
            }
        ),
    },
);

for my $test (@test_cases) {
    my ( $method, $params, $expected_response ) = @{$test}{qw/method params expected_response/};

    my $response = $openai->$method( %{$params} );

    cmp_deeply( $response, $expected_response );
}

done_testing();
