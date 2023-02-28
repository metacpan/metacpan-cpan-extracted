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

    my $response = $openai->edits(
        model       => 'text-davinci-edit-001',
        input       => 'What day of the wek is it?',
        instruction => 'Fix the spelling mistakes',
        temperature => 0,
    );

    is( $response->{choices}[0]{text}, "What day of the week is it?\n" );
}
