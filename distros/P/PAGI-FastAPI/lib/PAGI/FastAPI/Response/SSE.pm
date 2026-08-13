package PAGI::FastAPI::Response::SSE;

use v5.38;
use experimental 'class';
use version;

our $VERSION   = qv('v1.0.0');
our $AUTHORITY = 'cpan:MANWAR';

use Future::AsyncAwait;
use PAGI::SSE;

class PAGI::FastAPI::Response::SSE {
    field $generator :param;
    field $headers   :param = [];
    field $status    :param = 200;

    async method dispatch ($scope, $receive, $send) {
        my $sse = PAGI::SSE->new($scope, $receive, $send);

        await $sse->start(
            status  => $status,
            headers => [
                ['x-accel-buffering' => 'no'],
                @{$headers},
            ],
        );

        eval {
            await $generator->($sse);
        };
        if (my $err = $@) {
            await $sse->_trigger_error($err);
        }

        await $sse->run if !$sse->is_closed;
    }
}

=encoding utf-8

=head1 NAME

PAGI::FastAPI::Response::SSE - Server-Sent Events (SSE) Streaming Response for PAGI::FastAPI

=head1 VERSION

Version v1.0.0

=head1 SYNOPSIS

    use PAGI::FastAPI;

    my $app = PAGI::FastAPI->new();

    $app->get('/api/v1/notifications', sub ($c) {
        return $c->sse(async sub ($sse) {
            # Enable keepalive comments every 20 seconds
            await $sse->keepalive(20);

            # Replay missed messages on client reconnection
            if (my $last_id = $sse->last_event_id) {
                my @missed = get_events_since($last_id);
                for my $event (@missed) {
                    await $sse->send_event(%$event);
                }
            }

            # Send a structured SSE event
            await $sse->send_event(
                event => 'notification',
                id    => 'evt-101',
                data  => { user => 'alice', status => 'online' },
            );

            # Stream plain JSON messages
            await $sse->send_json({ message => 'System operational' });

            # Close stream when done
            await $sse->close(reason => 'complete');
        });
    });

=head1 DESCRIPTION

C<PAGI::FastAPI::Response::SSE> provides first-class, non-blocking
Server-Sent Events (SSE) streaming capabilities for L<PAGI::FastAPI>
applications by wrapping L<PAGI::SSE>.

It automatically manages connection lifecycles, flow control/backpressure,
heartbeats, custom headers (such as disabling Nginx buffering via
C<X-Accel-Buffering: no>), and structured event formatting (JSON auto-encoding,
event IDs, retry intervals, and keepalive comments).

=head1 CONSTRUCTOR

=head2 C<new(%options)>

Instantiates a new SSE response object. Accepts the following named parameters:

=over 4

=item * C<generator> (Required)

An C<async sub ($sse)> reference containing the streaming loop or event
emitter. Receives a L<PAGI::SSE> instance as its sole argument.

=item * C<headers> (Optional)

An ArrayRef of header key-value pairs (e.g., C<< [ ['X-Custom-Header' => 'value'] ] >>)
to return with the initial HTTP response stream. Defaults to C<[]>.

=item * C<status> (Optional)

Integer HTTP status code for the initial handshake response. Defaults to C<200>.

=back

=head1 METHODS

=head2 C<dispatch($scope, $receive, $send)>

    await $response->dispatch($scope, $receive, $send);

Executes the SSE response lifecycle against the low-level PAGI connection.
This method initialises L<PAGI::SSE>, issues the initial C<sse.start> event
with default and custom HTTP headers, runs the C<generator> callback, and
waits on C<$sse->run> until client disconnect or stream closure.

=head1 SEE ALSO

L<PAGI::SSE>, L<PAGI::FastAPI::Context>, L<PAGI::FastAPI>

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

    perldoc PAGI::FastAPI::Response::SSE

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
the terms of the Artistic License (2.0).

=cut

1; # End of PAGI::FastAPI::Response::SSE
