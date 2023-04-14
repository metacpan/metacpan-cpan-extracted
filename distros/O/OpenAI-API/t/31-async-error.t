#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use IO::Async::Loop;
use Test::More;
use Test::RequiresInternet;

use OpenAI::API::Config;
use OpenAI::API::Request::Completion;

if ( !$ENV{OPENAI_API_KEY} ) {
    plan skip_all => 'This test requires an OPENAI_API_KEY environment variable';
}

my $config = OpenAI::API::Config->new(
    timeout => 0.1,    # force timeout error
    retry   => 1,
);

my $request = OpenAI::API::Request::Completion->new(
    model       => "text-davinci-003",
    prompt      => "Say this is a test",
    max_tokens  => 10,
    temperature => 0,
    config      => $config,
);

my $loop = IO::Async::Loop->new();

my $future = $request->send_async()->then(
    sub {
        my $response_data = shift;
        fail('This test should raise a timeout exception');
    }
)->catch(
    sub {
        my $error = shift;
        isa_ok( $error, 'OpenAI::API::Error' );
        like( $error, qr/(?:timed out|timeout)/, 'error message' );
        is( $error->response->code, 500, 'response code' );
    }
);

$loop->await($future);

my $res = $future->get;

done_testing();
