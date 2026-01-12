package Net::HTTP2::nghttp2::Session;

use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(weaken);

# Session is implemented in XS, this is the Perl-side API wrapper

sub new_server {
    my ($class, %args) = @_;

    my $callbacks = delete $args{callbacks} // {};
    my $user_data = delete $args{user_data};
    my $settings  = delete $args{settings} // {};

    # Validate required callbacks
    for my $cb (qw(on_begin_headers on_header on_frame_recv)) {
        croak "Missing required callback: $cb" unless $callbacks->{$cb};
    }

    # Create the session via XS
    my $self = $class->_new_server_xs($callbacks, $user_data);

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

=head2 new_client

    my $session = Net::HTTP2::nghttp2::Session->new_client(%args);

Create a new client-side HTTP/2 session.

=head2 mem_recv

    my $consumed = $session->mem_recv($data);

Feed incoming data to the session. Returns number of bytes consumed.

=head2 mem_send

    my $data = $session->mem_send();

Get outgoing data from the session. Returns bytes to send to peer.

=head2 submit_response

    $session->submit_response($stream_id, %args);

Submit an HTTP/2 response on the given stream.

=head2 submit_push_promise

    my $promised_stream_id = $session->submit_push_promise($stream_id, %args);

Submit a server push promise.

=head2 want_read

    my $bool = $session->want_read();

Returns true if the session wants to read more data.

=head2 want_write

    my $bool = $session->want_write();

Returns true if the session has data to write.

=head2 resume_data

    $session->resume_data($stream_id);

Resume data production for a deferred stream.

=cut
