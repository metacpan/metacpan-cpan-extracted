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
        method            => 'listFiles',
        params            => {},
        expected_response => noclass(
            superhashof(
                {
                    object => 'list',
                    data   => array_each(
                        superhashof(
                            {
                                id         => ignore(),
                                object     => 'file',
                                bytes      => ignore(),
                                created_at => ignore(),
                                filename   => ignore(),
                                purpose    => ignore(),
                            }
                        )
                    ),
                }
            )
        ),
    },
);

SKIP:
for my $test (@test_cases) {
    my ( $method, $params, $expected_response ) = @{$test}{qw/method params expected_response/};

    my $tx = $openai->$method( { body => $params } );

    my $response = $tx->res->json;

    if ( $response->{data} && !@{ $response->{data} } ) {
        skip "Skipping test: no files found", 1;
    }

    cmp_deeply( $response, $expected_response )
        or diag( Dumper $response );
}

done_testing();
