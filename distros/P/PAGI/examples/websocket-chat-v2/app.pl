#!/usr/bin/env perl

#
# Multi-User Chat using PAGI::WebSocket
#
# This is a port of examples/10-chat-showcase using PAGI::WebSocket to
# demonstrate how the wrapper simplifies WebSocket handling.
#
# The HTTP, SSE, and State modules are identical to the original.
# Only the WebSocket handler is rewritten to use PAGI::WebSocket.
#
# Run with:
#   pagi-server --app examples/websocket-chat-v2/app.pl --port 5000
#
# Then open http://localhost:5000 in your browser
#

use strict;
use warnings;

use Future::AsyncAwait;
use File::Basename qw(dirname);
use lib dirname(__FILE__) . '/lib';

use ChatApp::State qw(get_stats);
use ChatApp::HTTP;
use ChatApp::WebSocket;
use ChatApp::SSE;

# Pre-instantiate handlers
my $http_handler = ChatApp::HTTP::handler();
my $ws_handler   = ChatApp::WebSocket::handler();
my $sse_handler  = ChatApp::SSE::handler();

# Simple request logging middleware
sub with_logging {
    my ($app) = @_;

    return async sub {
        my ($scope, $receive, $send) = @_;
        my $start = time();
        my $type = $scope->{type};
        my $path = $scope->{path} // '-';
        my $method = $scope->{method} // '-';

        # Wrap send to capture response status
        my $status = '-';
        my $wrapped_send = async sub {
            my ($event) = @_;
            if ($event->{type} =~ /\.start$/ && defined $event->{status}) {
                $status = $event->{status};
            }
            await $send->($event);
        };

        eval {
            await $app->($scope, $receive, $wrapped_send);
        };
        my $error = $@;

        my $duration = sprintf("%.3f", time() - $start);

        # Format: [TYPE] METHOD PATH STATUS DURATION
        my $client = $scope->{client} ? "$scope->{client}[0]" : '-';
        say STDERR "[$type] $method $path $status ${duration}s ($client)";

        die $error if $error;
    };
}

# Main application
my $app = with_logging(async sub {
    my ($scope, $receive, $send) = @_;
    my $type = $scope->{type} // '';
    my $path = $scope->{path} // '/';

    # Handle lifespan events
    if ($type eq 'lifespan') {
        return await _handle_lifespan($scope, $receive, $send);
    }

    # Route based on protocol and path
    if ($type eq 'websocket' && $path eq '/ws/chat') {
        return await $ws_handler->($scope, $receive, $send);
    }

    if ($type eq 'sse' && $path eq '/events') {
        return await $sse_handler->($scope, $receive, $send);
    }

    if ($type eq 'http') {
        return await $http_handler->($scope, $receive, $send);
    }

    # Unsupported protocol
    die "Unsupported scope type: $type";
});

async sub _handle_lifespan {
    my ($scope, $receive, $send) = @_;

    while (1) {
        my $event = await $receive->();

        if ($event->{type} eq 'lifespan.startup') {
            say STDERR "[lifespan] Application starting up...";

            # Initialize state (default rooms are created on module load)
            my $stats = get_stats();
            say STDERR "[lifespan] Initialized with $stats->{rooms_count} default rooms";

            await $send->({ type => 'lifespan.startup.complete' });
        }
        elsif ($event->{type} eq 'lifespan.shutdown') {
            say STDERR "[lifespan] Application shutting down...";

            my $stats = get_stats();
            say STDERR "[lifespan] Final stats: $stats->{users_online} users, $stats->{messages_total} messages";

            await $send->({ type => 'lifespan.shutdown.complete' });
            last;
        }
    }
}

$app;

__END__

=head1 NAME

Multi-User Chat using PAGI::WebSocket

=head1 SYNOPSIS

    pagi-server --app examples/websocket-chat-v2/app.pl --port 5000

=head1 DESCRIPTION

This is a port of the C<examples/10-chat-showcase> application that
demonstrates how L<PAGI::WebSocket> simplifies WebSocket handling.

The HTTP, SSE, and State modules are identical to the original.
Only the WebSocket handler is rewritten to use PAGI::WebSocket.

Compare C<lib/ChatApp/WebSocket.pm> with the original at
C<examples/10-chat-showcase/lib/ChatApp/WebSocket.pm> to see the
improvements.

=head2 Key Differences

=over

=item * WebSocket handler uses C<< PAGI::WebSocket->new >> wrapper

=item * Connection accepted with C<< $ws->accept >> instead of raw protocol

=item * Cleanup registered with C<< $ws->on_close >> callback

=item * Message loop uses C<< $ws->each_json >> for cleaner iteration

=item * Sending uses C<< $ws->send_json >> instead of raw JSON encoding

=back

=head1 ENDPOINTS

Same as the original:

=over

=item GET / - Chat frontend

=item GET /api/rooms - List rooms

=item GET /api/room/:name/history - Room message history

=item GET /api/stats - Server statistics

=item WS /ws/chat - WebSocket chat endpoint

=item SSE /events - Server-Sent Events stream

=back

=head1 SEE ALSO

L<PAGI::WebSocket>, L<examples/10-chat-showcase>

=cut
