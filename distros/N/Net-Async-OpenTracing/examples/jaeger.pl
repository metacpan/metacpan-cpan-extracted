#!/usr/bin/env perl 
use strict;
use warnings;

use Net::Async::OpenTracing;
use IO::Async::Loop;

use Log::Any qw($log);
use Log::Any::Adapter qw(Stdout), log_level => 'trace';

my $loop = IO::Async::Loop->new;

$loop->add(
    my $tracing = Net::Async::OpenTracing->new(
        host => '127.0.0.1',
        port => 6832,
    )
);

{
    my $batch = $tracing->new_batch();
    {
        my $span = $batch->new_span(
            'example_span'
        );
        $span->log('test message ' . $_ . ' from the parent') for 1..3;
        {
            my $child = $span->new_span('child_span');
            $child->log('message ' . $_ . ' from the child span') for 1..3;
        }
        {
            my $child = $span->new_span('child_span_2');
            $child->log('message ' . $_ . ' from the other child span') for 1..3;
        }
    }
}

$tracing->sync->get;

