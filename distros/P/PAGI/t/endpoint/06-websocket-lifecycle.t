#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Future;
use JSON::MaybeXS;

use lib 'lib';
use PAGI::Endpoint::WebSocket;

# Mock WebSocket
package MockWebSocket {
    use Future::AsyncAwait;

    sub new {
        my ($class, $events) = @_;
        bless {
            events => $events,
            idx => 0,
            sent => [],
            accepted => 0,
            closed => 0,
        }, $class;
    }
    async sub accept {
        my ($self) = @_;
        $self->{accepted} = 1;
    }
    sub is_accepted {
        my ($self) = @_;
        $self->{accepted};
    }
    async sub send_text {
        my ($self, $data) = @_;
        push @{$self->{sent}}, { type => 'text', data => $data };
    }
    async sub send_json {
        my ($self, $data) = @_;
        push @{$self->{sent}}, { type => 'json', data => $data };
    }
    sub sent {
        my ($self) = @_;
        $self->{sent};
    }
    sub on_close {
        my ($self, $cb) = @_;
        $self->{on_close_cb} = $cb;
    }
    async sub each_text {
        my ($self, $cb) = @_;
        for my $event (@{$self->{events}}) {
            await $cb->($event);
        }
        # After processing all messages, simulate disconnect
        if ($self->{on_close_cb}) {
            $self->{on_close_cb}->(1000, 'normal');
        }
    }
    async sub each_json {
        my ($self, $cb) = @_;
        for my $event (@{$self->{events}}) {
            await $cb->(JSON::MaybeXS::decode_json($event));
        }
        # After processing all messages, simulate disconnect
        if ($self->{on_close_cb}) {
            $self->{on_close_cb}->(1000, 'normal');
        }
    }
    async sub each_bytes {
        my ($self, $cb) = @_;
        for my $event (@{$self->{events}}) {
            await $cb->($event);
        }
        # After processing all messages, simulate disconnect
        if ($self->{on_close_cb}) {
            $self->{on_close_cb}->(1000, 'normal');
        }
    }
    async sub run {
        my ($self) = @_;
        # Simulate disconnect
        if ($self->{on_close_cb}) {
            $self->{on_close_cb}->(1000, 'normal');
        }
    }
}

package EchoEndpoint {
    use parent 'PAGI::Endpoint::WebSocket';
    use Future::AsyncAwait;

    our @log;

    async sub on_connect {
        my ($self, $ws) = @_;
        push @log, 'connect';
        await $ws->accept;
    }

    async sub on_receive {
        my ($self, $ws, $data) = @_;
        push @log, "receive:$data";
        await $ws->send_text("echo:$data");
    }

    sub on_disconnect {
        my ($self, $ws, $code, $reason) = @_;
        push @log, "disconnect:$code";
    }
}

subtest 'lifecycle methods are called in order' => sub {
    @EchoEndpoint::log = ();

    my $ws = MockWebSocket->new(['hello', 'world']);
    my $endpoint = EchoEndpoint->new;

    $endpoint->handle($ws)->get;

    is($EchoEndpoint::log[0], 'connect', 'on_connect called first');
    is($EchoEndpoint::log[1], 'receive:hello', 'first message received');
    is($EchoEndpoint::log[2], 'receive:world', 'second message received');
    like($EchoEndpoint::log[3], qr/disconnect/, 'on_disconnect called last');
};

subtest 'messages are echoed' => sub {
    @EchoEndpoint::log = ();

    my $ws = MockWebSocket->new(['test']);
    my $endpoint = EchoEndpoint->new;

    $endpoint->handle($ws)->get;

    is($ws->sent->[0]{data}, 'echo:test', 'message echoed');
};

done_testing;
