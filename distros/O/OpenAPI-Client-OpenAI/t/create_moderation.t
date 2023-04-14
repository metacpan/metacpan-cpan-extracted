#!perl

use strict;
use warnings;

use Data::Dumper;
use JSON;

use Test::More;
use Test::RequiresInternet;

use OpenAPI::Client::OpenAI;

if ( !$ENV{OPENAI_API_KEY} ) {
    plan skip_all => 'This test requires an OPENAI_API_KEY environment variable';
}

my $openai = OpenAPI::Client::OpenAI->new();

my @test_cases = (
    {
        method           => 'createModeration',
        params           => { input => 'I want to kill them' },
        expected_flagged => 1,
    },
    {
        method           => 'createModeration',
        params           => { input => 'I like turtles' },
        expected_flagged => 0,
    },
);

for my $test (@test_cases) {
    my ( $method, $params, $expected_flagged ) = @{$test}{qw/method params expected_flagged/};

    my $tx = $openai->$method( { body => $params } );

    my $response = $tx->res->json;

    is( !!$response->{results}[0]{flagged}, !!$expected_flagged )
        or diag( Dumper $response );
}

done_testing();
