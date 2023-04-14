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
        method => 'createChatCompletion',
        params => {
            model       => 'gpt-3.5-turbo',
            messages    => [ { "role" => "user", "content" => "Hello!" }, ],
            max_tokens  => 100,
            temperature => 0,
        },
        expected_message => {
            role    => 'assistant',
            content => re('\b(?:Hello|Hi|Hey)\b'),
        },
    },
    {
        method => 'createChatCompletion',
        params => {
            model       => 'gpt-3.5-turbo',
            messages    => [ { "role" => "user", "content" => "Hello!" }, ],
            max_tokens  => 100,
            temperature => 0,
            stop        => [ 'Hello', 'Hi', 'Hey' ],
        },
        expected_message => {
            role    => 'assistant',
            content => re('^\s*$'),
        },
    },
);

for my $test (@test_cases) {
    my ( $method, $params, $expected_message ) = @{$test}{qw/method params expected_message/};

    my $tx = $openai->$method( { body => $params } );

    my $response = $tx->res->json;

    cmp_deeply( $response->{choices}[0]{message}, $expected_message )
        or diag( Dumper $response );
}

done_testing();
