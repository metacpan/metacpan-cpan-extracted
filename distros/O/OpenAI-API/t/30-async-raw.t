#!/usr/bin/env perl

use strict;
use warnings;

use IO::Async::Loop;
use JSON::MaybeXS;
use Test::More;
use Test::RequiresInternet;

use OpenAI::API;
use OpenAI::API::Request::Completion;

if ( !$ENV{OPENAI_API_KEY} ) {
    plan skip_all => 'This test requires an OPENAI_API_KEY environment variable';
}

my $openai = OpenAI::API->new();

my $request = OpenAI::API::Request::Completion->new(
    model       => "text-davinci-003",
    prompt      => "Say this is a test",
    max_tokens  => 10,
    temperature => 0,
);

my $loop = IO::Async::Loop->new();

my $future = $request->send_async( http_response => 1 )->then(
    sub {
        my $response = shift;
        isa_ok( $response, 'HTTP::Response' );
        my $data = decode_json( $response->decoded_content );
        like( $data->{choices}[0]{text}, qr{test}, 'got expected string' );
    }
)->catch(
    sub {
        my $error = shift;
        diag("Error: $error\n");
        fail();
    }
);

$loop->await($future);

my $res = $future->get;

done_testing();
