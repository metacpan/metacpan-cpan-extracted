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
        method            => 'files',
        params            => {},
        expected_response => superhashof(
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
        ),
    },
);

SKIP:
for my $test (@test_cases) {
    my ( $method, $params, $expected_response ) = @{$test}{qw/method params expected_response/};

    my $response = $openai->$method( %{$params} );

    if ( $response->{data} && !@{ $response->{data} } ) {
        skip "Skipping test: no files found", 1;
    }

    cmp_deeply( $response, $expected_response );
}

done_testing();
