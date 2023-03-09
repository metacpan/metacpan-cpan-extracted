#!perl

use strict;
use warnings;
use Test::More;
use Test::RequiresInternet;

use OpenAI::API;

if ( !$ENV{OPENAI_API_KEY} ) {
    plan skip_all => 'This test requires an OPENAI_API_KEY environment variable';
}

my $openai = OpenAI::API->new();

my @test_cases = (
    {
        method           => 'moderations',
        params           => { input => 'I want to kill them' },
        expected_flagged => 1,
    },
    {
        method           => 'moderations',
        params           => { input => 'I like turtles' },
        expected_flagged => 0,
    },
);

for my $test (@test_cases) {
    my ( $method, $params, $expected_flagged ) = @{$test}{qw/method params expected_flagged/};

    my $response = $openai->$method( %{$params} );

    is( !!$response->{results}[0]{flagged}, !!$expected_flagged );
}

done_testing();
