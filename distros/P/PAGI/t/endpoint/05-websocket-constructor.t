#!/usr/bin/env perl
use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use Future;

use lib 'lib';

subtest 'can create websocket endpoint subclass' => sub {
    require PAGI::Endpoint::WebSocket;

    package ChatEndpoint {
        use parent 'PAGI::Endpoint::WebSocket';
        use Future::AsyncAwait;

        async sub on_connect {
            my ($self, $ws) = @_;
            await $ws->accept;
        }

        async sub on_receive {
            my ($self, $ws, $data) = @_;
            await $ws->send_text("echo: $data");
        }

        sub on_disconnect {
            my ($self, $ws, $code) = @_;
            # cleanup
        }
    }

    my $endpoint = ChatEndpoint->new;
    isa_ok($endpoint, 'PAGI::Endpoint::WebSocket');
};

subtest 'factory class method has default' => sub {
    require PAGI::Endpoint::WebSocket;

    is(PAGI::Endpoint::WebSocket->websocket_class, 'PAGI::WebSocket', 'default websocket_class');
};

subtest 'encoding attribute defaults to text' => sub {
    require PAGI::Endpoint::WebSocket;

    is(PAGI::Endpoint::WebSocket->encoding, 'text', 'default encoding is text');
};

subtest 'subclass can override encoding' => sub {
    package JSONEndpoint {
        use parent 'PAGI::Endpoint::WebSocket';
        sub encoding { 'json' }
    }

    is(JSONEndpoint->encoding, 'json', 'custom encoding');
};

done_testing;
