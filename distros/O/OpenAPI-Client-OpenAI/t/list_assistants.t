#!perl

use lib 't/lib';
use OpenAITests;

my @test_cases = (
    {
        method => 'listAssistants',
        params => {
            order       => 'asc',
            temperature => 0,
        },
        error => 0,
    },
    {
        method => 'listAssistants',
        params => {
            order       => 'asc',
            temperature => 0,
        },
        error => 1,
    },
);

my $openai = OpenAPI::Client::OpenAI->new( undef, assistants => 1 );

for my $test (@test_cases) {
    my ( $method, $params, $error ) = @{$test}{qw/method params error/};
    my $openai = OpenAPI::Client::OpenAI->new( undef, assistants => !$error );

    my $tx = $openai->$method( { body => $params } );

    my $response = $tx->res->json;

    if ($error) {
        ok exists $response->{error}, 'We should have an error if we do not pass in the "assistants" => 1 option'
            or explain $response;
    } else {
        ok !exists $response->{error}, 'We should not have an error if we pass in the "assistants" => 1 option'
            or explain $response;
    }
}

done_testing();
