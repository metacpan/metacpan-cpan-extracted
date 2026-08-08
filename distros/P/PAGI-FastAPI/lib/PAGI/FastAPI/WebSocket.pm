package PAGI::FastAPI::WebSocket;

use v5.36;
use version;

our $VERSION   = qv('v0.0.6');
our $AUTHORITY = 'cpan:MANWAR';

=encoding utf-8

=head1 NAME

PAGI::FastAPI::WebSocket - Asynchronous WebSocket connection object for PAGI::FastAPI

=head1 VERSION

Version v0.0.6

=cut

use Future::AsyncAwait;
use JSON::MaybeXS qw(encode_json decode_json);

=head1 SYNOPSIS

    use Future::AsyncAwait;
    use PAGI::FastAPI;

    my $app = PAGI::FastAPI->new;

    $app->websocket('/ws/{room_id}', handler => async sub ($ws, $deps) {
        await $ws->accept;

        my $room_id = $ws->path_params->{room_id};

        try {
            while (defined(my $msg = await $ws->receive_text)) {
                await $ws->send_text("Echo to room $room_id: $msg");
            }
        }
        catch ($err) {
            # Client disconnected or transport error
        }

        await $ws->close(1000, "Done");
    });

=head1 DESCRIPTION

C<PAGI::FastAPI::WebSocket> encapsulates an incoming WebSocket handshake and
provides an asynchronous, event-driven interface for exchanging text, binary,
and JSON frames over PAGI application servers.

=head1 METHODS

=head2 Constructor

=head3 new(%args)

Instantiates a new C<PAGI::FastAPI::WebSocket> context instance. Normally
created internally by L<PAGI::FastAPI> during connection dispatch.

=over 4

=item * C<scope> - The PAGI WebSocket connection scope hash ref.

=item * C<receive> - Asynchronous coderef yielding incoming PAGI event hashes.

=item * C<send> - Asynchronous coderef dispatching outgoing PAGI event hashes.

=item * C<path_params> - HashRef of extracted route path parameters.

=item * C<query_params> - HashRef of decoded URI query string parameters.

=back

=cut

sub new {
    my ($class, %args) = @_;

    return bless {
        scope        => $args{scope},
        receive      => $args{receive},
        send         => $args{send},
        path_params  => $args{path_params}  // {},
        query_params => $args{query_params} // {},
        accepted     => 0,
        closed       => 0,
    }, $class;
}

=head2 Attributes and Accessors

=head3 path_params()

Returns a HashRef containing path parameters extracted during route matching.

=cut

sub path_params { shift->{path_params} }

=head3 query_params()

Returns a HashRef containing query string parameters parsed from the
connection URI.

=cut

sub query_params { shift->{query_params} }

=head3 scope()

Returns the underlying PAGI scope HashRef.

=cut

sub scope { shift->{scope} }

=head3 is_accepted()

Returns a boolean indicating whether L</accept> has been executed
successfully.

=cut

sub is_accepted { shift->{accepted} }

=head3 is_closed()

Returns a boolean indicating whether the connection has been terminated or
closed.

=cut

sub is_closed { shift->{closed} }

=head2 Connection Handshake & Lifecycle

=head3 accept($subprotocol?)

    await $ws->accept;
    await $ws->accept('chat.v1');

Accepts the incoming WebSocket handshake. Optionally accepts a negotiated
subprotocol string.

=cut

async sub accept {
    my ($self, $subprotocol) = @_;
    return if $self->{accepted} || $self->{closed};

    my %event = ( type => 'websocket.accept' );
    $event{subprotocol} = $subprotocol if defined $subprotocol;

    await $self->{send}->(\%event);
    $self->{accepted} = 1;
}

=head3 close($code?, $reason?)

    await $ws->close;
    await $ws->close(1000, "Normal Closure");
    await $ws->close(1008, "Policy Violation");

Sends a L<websocket.close|PAGI> frame to gracefully terminate the connection.
Defaults to status code C<1000>.

=cut

async sub close {
    my ($self, $code, $reason) = @_;
    return if $self->{closed};

    await $self->{send}->({
        type   => 'websocket.close',
        code   => $code // 1000,
        reason => $reason // '',
    });

    $self->{closed} = 1;
}

=head2 Data Frame Operations

=head3 receive_text()

    my $text = await $ws->receive_text;

Blocks asynchronously until a text frame arrives from the client. Returns
C<undef> if the connection is closed or disconnected.

=cut

async sub receive_text ($self) {
    while (1) {
        my $event = await $self->receive;

        # Return undef ONLY when client disconnects or socket is closed
        if (!$event || $event->{type} eq 'websocket.disconnect') {
            $self->{closed} = 1;
            return undef;
        }

        # Handle message frames (accept both 'websocket.receive' and 'websocket.send')
        my $type = $event->{type} // '';
        if ($type eq 'websocket.receive' || $type eq 'websocket.send' || exists $event->{text}) {
            if (exists $event->{text}) {
                return $event->{text};
            }
            elsif (exists $event->{bytes}) {
                return "$event->{bytes}";
            }
        }
    }
}

=head3 receive_bytes()

    my $raw_bytes = await $ws->receive_bytes;

Blocks asynchronously until a binary frame arrives from the client. Returns
C<undef> if closed.

=cut

async sub receive_bytes ($self) {
    while (1) {
        my $event = await $self->receive;

        if (!$event || $event->{type} eq 'websocket.disconnect') {
            $self->{closed} = 1;
            return undef;
        }

        my $type = $event->{type} // '';
        if ($type eq 'websocket.receive' || $type eq 'websocket.send' || exists $event->{bytes}) {
            if (exists $event->{bytes}) {
                return $event->{bytes};
            }
        }
    }
}

=head3 receive_json()

    my $data = await $ws->receive_json;

Receives a text frame and deserialises it using L<JSON::MaybeXS>. Returns
C<undef> on disconnect.

=cut

async sub receive_json {
    my ($self) = @_;
    my $text = await $self->receive_text;
    return defined $text ? decode_json($text) : undef;
}

=head3 send_text($string)

    await $ws->send_text("Hello World");

Encodes and sends a UTF-8 text frame to the connected client.

=cut

async sub send_text {
    my ($self, $text) = @_;
    return if $self->{closed};

    await $self->{send}->({
        type => 'websocket.send',
        text => "$text",
    });
}

=head3 send_bytes($bytes)

    await $ws->send_bytes($binary_data);

Sends a raw binary frame to the connected client.

=cut

async sub send_bytes {
    my ($self, $bytes) = @_;
    return if $self->{closed};

    await $self->{send}->({
        type  => 'websocket.send',
        bytes => $bytes,
    });
}

=head3 send_json($data)

    await $ws->send_json({ status => 'ok', payload => $payload });

Serialises C<$data> to JSON using L<JSON::MaybeXS> and transmits it as a
text frame.

=cut

async sub send_json {
    my ($self, $data) = @_;
    await $self->send_text(encode_json($data));
}

=head2 Low-Level Event Receiver

=head3 receive()

    my $event = await $ws->receive;

Yields the next raw PAGI event hash from the server stream. Updates internal
state flags if a disconnect frame is encountered.

=cut

async sub receive {
    my ($self) = @_;

    return { type => 'websocket.disconnect', code => 1000 } if $self->{closed};

    my $event = await $self->{receive}->();

    if (!$event || $event->{type} eq 'websocket.disconnect') {
        $self->{closed} = 1;
    }

    return $event;
}

=head1 AUTHOR

Mohammad Sajid Anwar, C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/PAGI-FastAPI>

=head1 BUGS

Please report any bugs or feature requests through the web interface at L<https://github.com/manwar/PAGI-FastAPI/issues>.
I will be notified and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc PAGI::FastAPI::WebSocket

You can also look for information at:

=over 4

=item * BUG Report

L<https://github.com/manwar/PAGI-FastAPI/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/PAGI-FastAPI>

=item * Search MetaCPAN

L<https://metacpan.org/dist/PAGI-FastAPI/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Mohammad Sajid Anwar.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1; # End of PAGI::FastAPI::WebSocket
