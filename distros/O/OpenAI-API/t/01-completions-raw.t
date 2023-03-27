#!perl

use strict;
use warnings;

use Test::More;
use Test::RequiresInternet;

use JSON::MaybeXS;

use OpenAI::API::Request::Completion;

if ( !$ENV{OPENAI_API_KEY} ) {
    plan skip_all => 'This test requires an OPENAI_API_KEY environment variable';
}

my @test_cases = (
    {
        method => 'completions',
        params => {
            model       => 'text-davinci-003',
            prompt      => 'What is the capital of France?',
            max_tokens  => 100,
            temperature => 0,
        },
        expected_text_re => qr{\bParis\b},
    },
);

for my $test (@test_cases) {
    my ( $method, $params, $expected_text_re ) = @{$test}{qw/method params expected_text_re/};

    my $request = OpenAI::API::Request::Completion->new($params);

    my $res = $request->send( http_response => 1 );

    is( $res->code, 200 );

    my $data = decode_json( $res->decoded_content() );

    like( $data->{choices}[0]{text}, $expected_text_re );
}

done_testing();
