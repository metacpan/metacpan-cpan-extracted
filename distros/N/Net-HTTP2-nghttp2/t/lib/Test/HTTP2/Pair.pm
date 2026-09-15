package Test::HTTP2::Pair;

# A connected client/server session pair driven entirely through
# mem_send/mem_recv, for tests that need both ends of a real HTTP/2
# conversation.

use strict;
use warnings;
use Exporter 'import';
use Net::HTTP2::nghttp2::Session;
use Test::HTTP2::Frame qw(FRAME_HEADERS);

our @EXPORT_OK = qw(new_session_pair pump_sessions);

# Move bytes between the two sessions until neither has anything to send.
# The optional $on_server_bytes coderef receives every chunk the server
# writes, so callers can decode the raw wire image.
sub pump_sessions {
    my ($client, $server, $on_server_bytes) = @_;

    for my $round (1 .. 100) {
        my $moved = 0;

        my $client_bytes = $client->mem_send;
        if (defined($client_bytes) && length($client_bytes)) {
            $server->mem_recv($client_bytes);
            $moved = 1;
        }

        my $server_bytes = $server->mem_send;
        if (defined($server_bytes) && length($server_bytes)) {
            $on_server_bytes->($server_bytes) if $on_server_bytes;
            $client->mem_recv($server_bytes);
            $moved = 1;
        }

        return unless $moved;
    }

    die "session pump did not become idle";
}

# new_session_pair(
#     server_callbacks => \%callbacks,   # merged over no-op defaults
#     client_callbacks => \%callbacks,
#     server_settings  => \%settings,    # for send_connection_preface
#     client_settings  => \%settings,
#     server_args      => \%args,        # extra new_server arguments
#     request          => \%submit_request_args,
# )
#
# Exchanges connection prefaces, then submits the request if one is given.
# Returns ($client, $server), or ($client, $server, $client_stream_id,
# $server_stream_id) when a request was submitted.
sub new_session_pair {
    my (%args) = @_;

    my $server_callbacks = $args{server_callbacks} || {};
    my $client_callbacks = $args{client_callbacks} || {};

    my $server_stream_id;
    my $on_frame_recv = $server_callbacks->{on_frame_recv} || sub { return 0 };

    my $server = Net::HTTP2::nghttp2::Session->new_server(
        callbacks => {
            on_begin_headers => sub { return 0 },
            on_header        => sub { return 0 },
            %$server_callbacks,
            on_frame_recv => sub {
                my ($frame) = @_;
                if ($frame->{type} == FRAME_HEADERS && $frame->{stream_id} > 0) {
                    $server_stream_id = $frame->{stream_id};
                }
                return $on_frame_recv->(@_);
            },
        },
        %{ $args{server_args} || {} },
    );

    my $client = Net::HTTP2::nghttp2::Session->new_client(
        callbacks => {
            on_begin_headers   => sub { return 0 },
            on_header          => sub { return 0 },
            on_frame_recv      => sub { return 0 },
            on_data_chunk_recv => sub { return 0 },
            on_stream_close    => sub { return 0 },
            %$client_callbacks,
        },
    );

    $client->send_connection_preface(%{ $args{client_settings} || {} });
    $server->send_connection_preface(%{ $args{server_settings} || {} });
    pump_sessions($client, $server);

    return ($client, $server) unless $args{request};

    my $client_stream_id = $client->submit_request(%{ $args{request} });
    pump_sessions($client, $server);

    die "server did not receive the request stream"
        unless defined $server_stream_id;

    return ($client, $server, $client_stream_id, $server_stream_id);
}

1;
