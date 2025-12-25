#!/usr/bin/env perl

# Multi-User Chat Showcase Application
#
# This application demonstrates PAGI's capabilities:
# - HTTP: Static file serving and REST API
# - WebSocket: Real-time bidirectional chat
# - SSE: System-wide event notifications
# - Lifespan: Application startup/shutdown handling
#
# Run with:
#   perl -Ilib -Iexamples/10-chat-showcase/lib bin/pagi-server \
#     --app examples/10-chat-showcase/app.pl --port 5000
#
# Then open http://localhost:5000 in your browser

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

    return async sub  {
        my ($scope, $receive, $send) = @_;
        my $start = time();
        my $type = $scope->{type};
        my $path = $scope->{path} // '-';
        my $method = $scope->{method} // '-';

        # Wrap send to capture response status
        my $status = '-';
        my $wrapped_send = async sub  {
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

Multi-User Chat Showcase - PAGI Demo Application

=head1 SYNOPSIS

    perl -Ilib -Iexamples/10-chat-showcase/lib bin/pagi-server \
        --app examples/10-chat-showcase/app.pl --port 5000

=head1 DESCRIPTION

A comprehensive demonstration of PAGI's capabilities through a multi-user
chat application featuring:

=over

=item * B<WebSocket> - Real-time bidirectional chat messaging

=item * B<HTTP> - Static file serving and REST API endpoints

=item * B<SSE> - Server-Sent Events for system notifications

=item * B<Lifespan> - Application lifecycle management

=back

=head1 ENDPOINTS

=head2 HTTP

=over

=item GET /

Serves the chat frontend (index.html)

=item GET /api/rooms

Lists all chat rooms with user counts

=item GET /api/room/:name/history

Gets message history for a room

=item GET /api/stats

Server statistics (uptime, users, messages)

=back

=head2 WebSocket

=over

=item /ws/chat

WebSocket endpoint for chat. Connect with C<?name=Username> query parameter.

=back

=head2 SSE

=over

=item /events

Server-Sent Events stream for system notifications

=back

=head1 FEATURES

=head2 Chat Features

=over

=item * Multiple chat rooms (create, join, leave)

=item * Real-time message broadcasting

=item * Typing indicators

=item * Private messaging (/pm user message)

=item * User presence tracking

=item * Message history (last 100 per room)

=back

=head2 Commands

Type these in chat:

    /help           - Show available commands
    /rooms          - List all rooms
    /users          - List users in current room
    /join <room>    - Join or create a room
    /leave          - Leave current room
    /pm <user> <msg> - Send private message
    /nick <name>    - Change your nickname
    /me <action>    - Send action message

=head1 AUTHOR

PAGI Demo Application

=cut
