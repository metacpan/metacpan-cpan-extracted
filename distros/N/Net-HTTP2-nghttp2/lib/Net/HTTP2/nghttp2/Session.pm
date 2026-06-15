package Net::HTTP2::nghttp2::Session;

use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(weaken);
use Net::HTTP2::nghttp2;  # XS bootstrap (loads _new_server_xs etc.)

# Session is implemented in XS, this is the Perl-side API wrapper

sub new_server {
    my ($class, %args) = @_;

    my $callbacks = delete $args{callbacks} // {};
    my $user_data = delete $args{user_data};
    my $settings  = delete $args{settings} // {};

    # Session options (passed to nghttp2_option / nghttp2_session_server_new2)
    my $max_send_header_block_length = delete $args{max_send_header_block_length};
    my $stream_reset_burst = delete $args{stream_reset_burst};
    my $stream_reset_rate  = delete $args{stream_reset_rate};

    # Validate required callbacks
    for my $cb (qw(on_begin_headers on_header on_frame_recv)) {
        croak "Missing required callback: $cb" unless $callbacks->{$cb};
    }

    # Build options hash for XS if any session options are set
    my %options;
    $options{max_send_header_block_length} = $max_send_header_block_length
        if defined $max_send_header_block_length;

    # Rapid Reset (CVE-2023-44487) RST_STREAM rate limit. burst and rate must be
    # set together; they map to nghttp2_option_set_stream_reset_rate_limit.
    if (defined $stream_reset_burst || defined $stream_reset_rate) {
        croak "stream_reset_burst and stream_reset_rate must be set together"
            unless defined $stream_reset_burst && defined $stream_reset_rate;
        $options{stream_reset_burst} = $stream_reset_burst;
        $options{stream_reset_rate}  = $stream_reset_rate;
    }

    # Create the session via XS
    my $self = %options
        ? $class->_new_server_xs($callbacks, $user_data, \%options)
        : $class->_new_server_xs($callbacks, $user_data);

    # Apply initial settings
    if (%$settings) {
        $self->submit_settings($settings);
    }

    return $self;
}

sub new_client {
    my ($class, %args) = @_;

    my $callbacks = delete $args{callbacks} // {};
    my $user_data = delete $args{user_data};

    return $class->_new_client_xs($callbacks, $user_data);
}

# High-level request submission (client-side)
# Body can be: undef (no body), string (static body), or CODE ref (streaming callback).
# Streaming callback receives ($stream_id, $max_length) and returns:
#   ($data, $eof_flag) - send data, eof=1 closes stream
#   undef              - defer; call resume_stream() when data is ready
sub submit_request {
    my ($self, %args) = @_;

    my $method    = delete $args{method} // 'GET';
    my $path      = delete $args{path} // '/';
    my $scheme    = delete $args{scheme} // 'https';
    my $authority = delete $args{authority};
    my $headers   = delete $args{headers} // [];
    my $body      = delete $args{body};

    # Build pseudo-headers + regular headers
    my @nv = (
        [':method', $method],
        [':path', $path],
        [':scheme', $scheme],
    );
    push @nv, [':authority', $authority] if defined $authority;
    push @nv, @$headers;

    return $self->_submit_request_xs(\@nv, $body);
}

# Convenience method to send server connection preface (SETTINGS frame)
sub send_connection_preface {
    my ($self, %settings) = @_;

    # Default settings for server
    %settings = (
        max_concurrent_streams => 100,
        initial_window_size    => 65535,
        %settings,
    ) unless %settings;

    return $self->submit_settings(\%settings);
}

# High-level response submission
sub submit_response {
    my ($self, $stream_id, %args) = @_;

    my $status  = delete $args{status} // 200;
    my $headers = delete $args{headers} // [];
    my $body    = delete $args{body};
    my $data_cb = delete $args{data_callback};
    my $cb_data = delete $args{callback_data};

    # Build pseudo-headers + regular headers
    my @nv = (
        [':status', $status],
        @$headers,
    );

    if (defined $body && !ref($body)) {
        # Static body - convert to simple streaming callback
        my $sent = 0;
        my $body_bytes = $body;
        $data_cb = sub {
            my ($stream_id, $max_len) = @_;
            return ('', 1) if $sent;  # EOF
            $sent = 1;
            return ($body_bytes, 1);  # data + EOF
        };
        return $self->_submit_response_streaming($stream_id, \@nv, $data_cb, undef);
    }
    elsif (ref($body) eq 'CODE') {
        # CODE ref body - streaming callback data provider
        return $self->_submit_response_streaming($stream_id, \@nv, $body, $cb_data);
    }
    elsif ($data_cb) {
        # Dynamic body - use callback-based data provider
        return $self->_submit_response_streaming($stream_id, \@nv, $data_cb, $cb_data);
    }
    else {
        # No body (e.g., 204 No Content, redirects)
        return $self->_submit_response_no_body($stream_id, \@nv);
    }
}

# Resume a deferred stream (call after data becomes available)
sub resume_stream {
    my ($self, $stream_id) = @_;
    $self->_clear_deferred($stream_id);
    return $self->resume_data($stream_id);
}

# High-level push promise submission
sub submit_push_promise {
    my ($self, $stream_id, %args) = @_;

    my $method  = delete $args{method} // 'GET';
    my $path    = delete $args{path} or croak "path required for push promise";
    my $scheme  = delete $args{scheme} // 'https';
    my $authority = delete $args{authority};
    my $headers = delete $args{headers} // [];

    my @nv = (
        [':method', $method],
        [':path', $path],
        [':scheme', $scheme],
    );
    push @nv, [':authority', $authority] if defined $authority;
    push @nv, @$headers;

    return $self->_submit_push_promise_xs($stream_id, \@nv);
}

1;

__END__

=head1 NAME

Net::HTTP2::nghttp2::Session - HTTP/2 session management

=head1 SYNOPSIS

    use Net::HTTP2::nghttp2::Session;

    my $session = Net::HTTP2::nghttp2::Session->new_server(
        callbacks => {
            on_begin_headers => sub {
                my ($session, $stream_id) = @_;
                # New stream started
            },
            on_header => sub {
                my ($session, $stream_id, $name, $value, $flags) = @_;
                # Header received
            },
            on_frame_recv => sub {
                my ($session, $frame) = @_;
                # Frame received
            },
            on_stream_close => sub {
                my ($session, $stream_id, $error_code) = @_;
                # Stream closed
            },
            on_data_chunk_recv => sub {
                my ($session, $stream_id, $data, $flags) = @_;
                # Body data received
            },
        },
    );

    # Send connection preface
    $session->send_connection_preface(
        max_concurrent_streams => 100,
    );

    # Process incoming data
    $session->mem_recv($incoming_bytes);

    # Get outgoing data to send
    my $outgoing = $session->mem_send();

    # Submit a response
    $session->submit_response($stream_id,
        status  => 200,
        headers => [
            ['content-type', 'text/html'],
        ],
        body => '<html>...</html>',
    );

=head1 METHODS

=head2 new_server

    my $session = Net::HTTP2::nghttp2::Session->new_server(%args);

Create a new server-side HTTP/2 session.

Arguments:

=over 4

=item callbacks

Hashref of callback handlers. Required callbacks: C<on_begin_headers>,
C<on_header>, C<on_frame_recv>. Optional: C<on_data_chunk_recv>,
C<on_stream_close>.

=item user_data

Optional scalar passed to callbacks.

=item settings

Optional hashref of initial HTTP/2 settings.

=item stream_reset_burst / stream_reset_rate

Configure the incoming-C<RST_STREAM> rate limit (nghttp2's HTTP/2 Rapid Reset,
CVE-2023-44487, mitigation). Both must be given together. They map to
C<nghttp2_option_set_stream_reset_rate_limit(option, burst, rate)>: a token
bucket of C<burst> tokens refilling at C<rate> tokens/second, one token per
incoming C<RST_STREAM>. When the bucket is empty nghttp2 sends GOAWAY and tears
down the connection. Omit both to use nghttp2's own defaults (burst 1000,
rate 33). Requires nghttp2 >= 1.57.

=back

=head2 new_client

    my $session = Net::HTTP2::nghttp2::Session->new_client(%args);

Create a new client-side HTTP/2 session.

Arguments:

=over 4

=item callbacks

Hashref of callback handlers. Recommended: C<on_header>,
C<on_data_chunk_recv>, C<on_stream_close>.

=item user_data

Optional scalar passed to callbacks.

=back

=head2 send_connection_preface

    $session->send_connection_preface(%settings);

Send HTTP/2 connection preface (SETTINGS frame). Default settings:
C<max_concurrent_streams =E<gt> 100>, C<initial_window_size =E<gt> 65535>.

Additional settings:

=over 4

=item enable_connect_protocol

Set to 1 to advertise RFC 8441 extended CONNECT support
(C<SETTINGS_ENABLE_CONNECT_PROTOCOL>). Required for WebSocket over HTTP/2.

=back

=head2 mem_recv

    my $consumed = $session->mem_recv($data);

Feed incoming data to the session. Returns number of bytes consumed.
Triggers registered callbacks as frames are parsed.

=head2 mem_send

    my $data = $session->mem_send();

Get outgoing data from the session. Returns bytes to send to peer
(empty string if nothing pending).

=head2 submit_request

    my $stream_id = $session->submit_request(%args);

Submit an HTTP/2 request (client-side). Returns the stream ID.

Arguments:

=over 4

=item method

HTTP method. Default: C<'GET'>.

=item path

Request path. Default: C<'/'>.

=item scheme

URL scheme. Default: C<'https'>.

=item authority

Host authority (e.g. C<'example.com'>).

=item headers

Arrayref of C<[$name, $value]> pairs for additional headers (including
pseudo-headers like C<:protocol> for RFC 8441 extended CONNECT).

=item body

Request body. Can be:

=over 4

=item C<undef> (or omitted)

No body. HEADERS frame sent with END_STREAM.

=item String

Static body. Sent as DATA frame(s) with END_STREAM after the last frame.

=item CODE ref

Streaming callback for bidirectional streams. The callback receives
C<($stream_id, $max_length)> and must return one of:

=over 4

=item C<($data, $eof_flag)>

Send C<$data> as a DATA frame. If C<$eof_flag> is true, END_STREAM is set.

=item C<undef>

Defer data production. Call C<resume_stream($stream_id)> when data is ready.

=back

This is required for protocols that keep the stream open for bidirectional
exchange, such as WebSocket over HTTP/2 (RFC 8441 extended CONNECT).

=back

=back

=head2 submit_response

    $session->submit_response($stream_id, %args);

Submit an HTTP/2 response on the given stream.

Arguments:

=over 4

=item status

HTTP status code. Default: C<200>.

=item headers

Arrayref of C<[$name, $value]> pairs.

=item body

Response body. Same types as C<submit_request>: C<undef> (no body),
string (static body), or CODE ref (streaming callback with identical
signature).

=item data_callback

Alternative to passing a CODE ref as C<body>. Callback with the same
streaming signature.

=item callback_data

Optional user data passed as third argument to the streaming callback.

=back

=head2 submit_push_promise

    my $promised_stream_id = $session->submit_push_promise($stream_id, %args);

Submit a server push promise.

=head2 submit_data

    $session->submit_data($stream_id, $data, $eof);

Push data directly onto an existing stream. The stream must already have
a data provider (established by C<submit_request> or C<submit_response>
with a CODE ref or C<data_callback>). This replaces the streaming callback
with a one-shot static body, then resumes the stream.

Arguments:

=over 4

=item C<$stream_id>

The stream to send data on.

=item C<$data>

The data to send. Can be C<undef> for an empty DATA frame.

=item C<$eof>

If true, the DATA frame will include END_STREAM, closing the stream.

=back

This is useful when you have data available outside the streaming callback
context and want to push it directly, such as forwarding WebSocket frames
received from another source.

=head2 resume_stream

    $session->resume_stream($stream_id);

Resume data production for a deferred stream. Call this after a streaming
body callback has returned C<undef> and new data is available. Works for
both request and response streams.

=head2 terminate_session

    $session->terminate_session($error_code);

Send a GOAWAY frame and terminate the session. The C<$error_code> should
be an nghttp2 error code (0 for C<NGHTTP2_NO_ERROR>).

=head2 submit_rst_stream

    $session->submit_rst_stream($stream_id, $error_code);

Send a RST_STREAM frame to abnormally terminate a stream. The
C<$error_code> should be an HTTP/2 error code (e.g. 0 for NO_ERROR,
8 for CANCEL).

=head2 submit_ping

    $session->submit_ping($ack, $opaque_data);

Send a PING frame. Set C<$ack> to 1 for a PING ACK response, 0 for an
unsolicited PING. C<$opaque_data> must be exactly 8 bytes, or C<undef>
for default.

=head2 submit_window_update

    $session->submit_window_update($stream_id, $window_size_increment);

Send a WINDOW_UPDATE frame to increase the flow control window. Use
C<$stream_id = 0> for connection-level flow control, or a specific
stream ID for stream-level.

=head2 get_stream_user_data

    my $data = $session->get_stream_user_data($stream_id);

Retrieve user data associated with a stream. Returns C<undef> if no
data is set.

=head2 set_stream_user_data

    $session->set_stream_user_data($stream_id, $data);

Associate arbitrary user data with a stream. Useful for storing
per-stream application state.

=head2 is_stream_deferred

    my $bool = $session->is_stream_deferred($stream_id);

Returns true if the stream's data provider has been deferred (i.e. the
streaming callback returned C<undef>). The stream can be resumed with
C<resume_stream()>.

=head2 want_read

    my $bool = $session->want_read();

Returns true if the session wants to read more data.

=head2 want_write

    my $bool = $session->want_write();

Returns true if the session has data to write.

=head2 resume_data

    $session->resume_data($stream_id);

Low-level resume for deferred data production. Prefer C<resume_stream()>
which also clears the internal deferred flag.

=head1 CALLBACKS

All callbacks receive positional arguments and should return 0 on success.

=head2 on_begin_headers

    sub { my ($stream_id, $frame_type, $flags) = @_; return 0; }

Called when a new headers block begins (new stream or trailers).

=head2 on_header

    sub { my ($stream_id, $name, $value, $flags) = @_; return 0; }

Called for each header. Pseudo-headers (C<:method>, C<:path>, C<:scheme>,
C<:authority>, C<:status>, C<:protocol>) are delivered before regular headers.

=head2 on_frame_recv

    sub { my ($frame_hashref) = @_; return 0; }

Called when a complete frame is received. The hashref contains: C<type>,
C<flags>, C<stream_id>, C<length>.

=head2 on_data_chunk_recv

    sub { my ($stream_id, $data, $flags) = @_; return 0; }

Called when body data is received on a stream.

=head2 on_stream_close

    sub { my ($stream_id, $error_code) = @_; return 0; }

Called when a stream is closed.

=cut
