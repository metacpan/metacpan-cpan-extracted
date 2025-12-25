#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Future;

use lib 'lib';
use PAGI::Endpoint::SSE;

# Mock SSE
package MockSSE {
    use Future::AsyncAwait;

    sub new {
        my ($class) = @_;
        bless {
            sent => [],
            started => 0,
            keepalive => 0,
            closed => 0,
        }, $class;
    }
    async sub start {
        my ($self) = @_;
        $self->{started} = 1;
        return $self;
    }
    sub keepalive {
        my ($self, $interval) = @_;
        $self->{keepalive} = $interval;
        return $self;
    }
    sub on_close {
        my ($self, $cb) = @_;
        $self->{on_close_cb} = $cb;
        return $self;
    }
    async sub send_event {
        my ($self, %opts) = @_;
        push @{$self->{sent}}, \%opts;
    }
    async sub run {
        my ($self) = @_;
        # Simulate disconnect
        if ($self->{on_close_cb}) {
            $self->{on_close_cb}->();
        }
    }
    sub sent {
        my ($self) = @_;
        $self->{sent};
    }
    sub last_event_id {
        my ($self) = @_;
        undef;
    }
}

package MetricsEndpoint {
    use parent 'PAGI::Endpoint::SSE';
    use Future::AsyncAwait;

    sub keepalive_interval { 25 }

    our @log;

    async sub on_connect {
        my ($self, $sse) = @_;
        push @log, 'connect';
        await $sse->send_event(event => 'connected', data => { ok => 1 });
    }

    sub on_disconnect {
        my ($self, $sse) = @_;
        push @log, 'disconnect';
    }
}

subtest 'lifecycle methods are called' => sub {
    @MetricsEndpoint::log = ();

    my $sse = MockSSE->new;
    my $endpoint = MetricsEndpoint->new;

    $endpoint->handle($sse)->get;

    is($MetricsEndpoint::log[0], 'connect', 'on_connect called');
    is($MetricsEndpoint::log[1], 'disconnect', 'on_disconnect called');
};

subtest 'keepalive is configured' => sub {
    my $sse = MockSSE->new;
    my $endpoint = MetricsEndpoint->new;

    $endpoint->handle($sse)->get;

    is($sse->{keepalive}, 25, 'keepalive interval set');
};

subtest 'events are sent' => sub {
    my $sse = MockSSE->new;
    my $endpoint = MetricsEndpoint->new;

    $endpoint->handle($sse)->get;

    is($sse->sent->[0]{event}, 'connected', 'event sent');
};

subtest 'to_app returns PAGI-compatible coderef' => sub {
    my $app = MetricsEndpoint->to_app;

    ref_ok($app, 'CODE', 'to_app returns coderef');
};

done_testing;
