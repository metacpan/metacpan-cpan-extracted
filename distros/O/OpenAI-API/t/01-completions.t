#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

use OpenAI::API;

SKIP: {
    skip "This test requires a OPENAI_KEY environment variable", 1 if !$ENV{OPENAI_KEY};

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

    ok( $response->is_success ) or note( $response->status_line );
}
