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

my $openai = OpenAI::API->new( timeout => 0.01, retry => 1 );

my @test_cases = (
    {
        method           => 'completions',
        params           => { model => 'text-davinci-003', prompt => 'How would you explain the idea of justice?' },
        exception_re     => qr/timed out/i,
        exception_struct => noclass(
            superhashof(
                {
                    message  => re('timed out'),
                    request  => ignore(),
                    response => ignore(),
                }
            )
        ),
    },
);

for my $test (@test_cases) {
    my ( $method, $params, $exception_re, $exception_struct ) =
        @{$test}{qw/method params exception_re exception_struct/};

    eval {
        my $response = $openai->$method( %{$params} );
        fail("Expected error, got a valid response");
        1;
    } or do {
        my $error = $@;
        like( $error, $exception_re );
        cmp_deeply( $error, $exception_struct );
    };
}

done_testing();
