#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::RequiresInternet;

use OpenAI::API;

if (!$ENV{OPENAI_API_KEY}) {
    plan skip_all => 'This test requires an OPENAI_API_KEY environment variable';
}

my $openai = OpenAI::API->new( timeout => 0.01, retry => 1 );

my @test_cases = (
    {
        method    => 'completions',
        params    => { model => 'text-davinci-003', prompt => 'How would you explain the idea of justice?' },
        exception => qr/timed out/i,
    },
);

for my $test (@test_cases) {
    my ( $method, $params, $exception ) = @{$test}{qw/method params exception/};

    throws_ok { my $response = $openai->$method( %{$params} ); } $exception;
}

done_testing();
