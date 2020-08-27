#!/usr/bin/env perl 
use strict;
use warnings;

use utf8;

use OpenTracing::Any qw($tracer);
use Net::Async::OpenTracing;
use IO::Async::Loop;

use Log::Any qw($log);
use Log::Any::Adapter qw(Stdout), log_level => 'trace';

my $loop = IO::Async::Loop->new;

$loop->add(
    # This should work with a default jæger instance,
    # as described in https://www.jaegertracing.io/docs/1.17/getting-started/
    my $tracing = Net::Async::OpenTracing->new(
        host => '127.0.0.1',
        port => 6832,
    )
);

{
    {
        my $span = $tracer->span(
            operation_name => 'example_span'
        );
        $span->log('test message ' . $_ . ' from the parent') for 1..3;
        {
            my $child = $span->span(operation_name => 'child_span');
            $child->log('message ' . $_ . ' from the child span') for 1..3;
        }
    }
}

warn "Sync all pending spans";
$tracing->sync->get;
warn "Sync done";

