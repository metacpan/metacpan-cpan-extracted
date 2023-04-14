#!/usr/bin/env perl

use strict;
use warnings;

use IO::Async::Loop;
use Test::More;
use Test::RequiresInternet;

use OpenAI::API;
use OpenAI::API::Request::Completion;

if ( !$ENV{OPENAI_API_KEY} ) {
    plan skip_all => 'This test requires an OPENAI_API_KEY environment variable';
}

my @test_cases = (
    { event_loop_class => 'IO::Async::Loop' },
    { event_loop_class => 'IO::Async::Loop::AnyEvent', optional => 1 },
    { event_loop_class => 'IO::Async::Loop::Mojo',     optional => 1 },
    { event_loop_class => 'IO::Async::Loop::POE',      optional => 1 },
);

for my $test (@test_cases) {
    my $event_loop_class = $test->{event_loop_class};

    # We are not using use_ok() because some of these modules are
    # optional and expected to fail, and we don't want to mark the
    # test as failed
    eval "require $event_loop_class" or do {
        if ($test->{optional}) {
            note("Module $event_loop_class is not installed");
        } else {
            fail("Error loading $event_loop_class");
        }
        next;
    };

    pass("use $event_loop_class");

    my $request = OpenAI::API::Request::Completion->new(
        model       => "text-davinci-003",
        prompt      => "Say this is a test",
        max_tokens  => 10,
        temperature => 0,
        config      => { event_loop_class => $event_loop_class },
    );

    my $loop = $request->event_loop();
    isa_ok( $loop, $event_loop_class );

    my $future = $request->send_async()->then(
        sub {
            my $content = shift;
            isa_ok( $content, 'HASH' );
            like( $content->{choices}[0]{text}, qr{test}, 'got expected string' );
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
}

done_testing();
