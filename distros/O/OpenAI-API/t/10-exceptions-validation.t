#!perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use OpenAI::API;

my $openai = OpenAI::API->new( api_key => '' );

# force error
$ENV{OPENAI_API_KEY} = undef;

my @test_cases = (
    {
        method    => 'new',
        params    => {},
        exception => qr/Missing OPENAI_API_KEY/,
    },
    {
        method    => 'completions',
        params    => {},
        exception => qr/Missing required arguments: model, prompt/,
    },
    {
        method    => 'edits',
        params    => {},
        exception => qr/Missing required arguments: instruction, model/,
    },
    {
        method    => 'embeddings',
        params    => {},
        exception => qr/Missing required arguments: input, model/,
    },
    {
        method    => 'moderations',
        params    => {},
        exception => qr/Missing required arguments: input/,
    },
);

for my $test (@test_cases) {
    my ( $method, $params, $exception ) = @{$test}{qw/method params exception/};

    throws_ok { my $response = $openai->$method( %{$params} ); } $exception;
}

done_testing();
