#!perl

use strict;
use warnings;
use Test::More;
use Test::RequiresInternet;

plan tests => 1;

use OpenAI::API;

SKIP: {
    skip "This test requires a OPENAI_KEY environment variable", 1 if !$ENV{OPENAI_API_KEY};

    my $openai = OpenAI::API->new();

    my $response = $openai->completions(
        model             => 'text-davinci-003',
        prompt            => 'What is the capital of France?',
        max_tokens        => 2048,
        temperature       => 0.5,
        top_p             => 1,
        frequency_penalty => 0,
        presence_penalty  => 0
    );

    like( $response->{choices}[0]{text}, qr{\bParis\b} );
}
