#!perl

use strict;
use warnings;
use Test::More;
use Test::RequiresInternet;

plan tests => 1;

use OpenAI::API;

SKIP: {
    skip "This test requires a OPENAI_KEY environment variable", 1 if !$ENV{OPENAI_API_KEY};

    my $openai = OpenAI::API->new();

    my $response = $openai->moderations( input => 'I want to kill them.' );

    ok( $response->{results}[0]{categories}{violence} );
}
