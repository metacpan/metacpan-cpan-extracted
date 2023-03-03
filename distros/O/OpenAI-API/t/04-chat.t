#!perl

use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::RequiresInternet;

plan tests => 1;

use OpenAI::API;

SKIP: {
    skip "This test requires a OPENAI_KEY environment variable", 1 if !$ENV{OPENAI_API_KEY};

    my $openai = OpenAI::API->new();

    my $response = $openai->chat(
        model       => 'gpt-3.5-turbo',
        messages    => [ { "role" => "user", "content" => "Hello!" }, ],
        max_tokens  => 2048,
        temperature => 0,
    );

    cmp_deeply(
        $response->{choices}[0]{message},
        {
            role    => 'assistant',
            content => re('\b(?:Hello|Hi|Hey)\b'),
        }
    );
}
