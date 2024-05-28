#!perl

use strict;
use warnings;

use Data::Dumper;
use JSON;

use Test::More;
use Test::RequiresInternet;

use OpenAPI::Client::OpenAI;

if ( !$ENV{OPENAI_API_KEY} ) {
    plan skip_all =>
      'This test requires an OPENAI_API_KEY environment variable';
}

my $openai = OpenAPI::Client::OpenAI->new( undef, assistants => 1 );

my @test_cases = (
    {
        method => 'listAssistants',
        params => {
            order       => 'asc',
            temperature => 0,
        },
        error => 0,
    },
);

for my $test (@test_cases) {
    my ( $method, $params ) = @{$test}{qw/method params/};

    my $tx = $openai->$method( { body => $params } );

    my $response = $tx->res->json;

    ok !exists $response->{error},
      'We should not have an error if we pass in the "assistants" => 1 option'
      or diag( Dumper $response );
}

done_testing();
