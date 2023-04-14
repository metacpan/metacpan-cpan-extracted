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
        method            => 'models',
        params            => {},
        expected_response => noclass(superhashof(
            {
                object => 'list',
                data   => array_each(
                    superhashof(
                        {
                            id         => ignore(),                 # e.g. ada, babbage, etc.
                            object     => 'model',
                            owned_by   => ignore(),
                            permission => array_each( ignore() ),
                        }
                    )
                ),
            }
        )),
    },
    {
        method            => 'model_retrieve',
        params            => { model => 'text-davinci-003' },
        expected_response => noclass({
            id         => 'text-davinci-003',
            created    => ignore(),
            object     => 'model',
            owned_by   => 'openai-internal',
            parent     => ignore(),
            permission => array_each( ignore() ),
            root       => 'text-davinci-003',
        }),
    },

);

for my $test (@test_cases) {
    my ( $method, $params, $expected_response ) = @{$test}{qw/method params expected_response/};

    my $response = $openai->$method( %{$params} );
    cmp_deeply( $response, $expected_response );
}

done_testing();
