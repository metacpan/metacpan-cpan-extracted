package Net::Async::OpenTracing;
# ABSTRACT: wire protocol support for the opentracing.io API

use strict;
use warnings;

our $VERSION = '1.000';
our $AUTHORITY = 'cpan:TEAM'; # AUTHORITY

use parent qw(IO::Async::Notifier);

no indirect;
use utf8;

=encoding utf8

=head1 NAME

Net::Async::OpenTracing - OpenTracing APM via L<IO::Async>

=head1 SYNOPSIS

 use Net::Async::OpenTracing;
 use IO::Async::Loop;
 use OpenTracing::Any qw($tracer);
 my $loop = IO::Async::Loop->new;
 $loop->add(
    my $tracing = Net::Async::OpenTracing->new(
        host => '127.0.0.1',
        port => 6832,
    )
 );
 $tracer->span(operation_name => 'example');
 # Manual sync - generally only needed on exit
 $tracing->sync->get;

=head1 DESCRIPTION

This all relies on the abstract L<OpenTracing> interface, so that'd be
the first port of call for official documentation.

=head2 Setting up and testing

If you want to experiment with this, start by setting up a Jæger instance in Docker like so:

 docker run -d --name jaeger \
  -e COLLECTOR_ZIPKIN_HTTP_PORT=9411 \
  -p 5775:5775/udp \
  -p 6831:6831/udp \
  -p 6832:6832/udp \
  -p 5778:5778 \
  -p 16686:16686 \
  -p 14268:14268 \
  -p 9411:9411 \
  jaegertracing/all-in-one:1.17

If you have a Kubernetes stack installed then you likely already have this available.

UDP port 6832 is typically the "binary Thrift" port, so that's likely where you would
want this module configured to send data (other ports and protocols are available).

Set up an L<Net::Async::OpenTracing> instance with those connection details:

 use Net::Async::OpenTracing;
 my $loop = IO::Async::Loop->new;
 $loop->add(
    my $tracing = Net::Async::OpenTracing->new(
        host => '127.0.0.1',
        port => 6832,
    )
 );
 # Now generate some traffic
 {
  my $span = $tracer->span(
   operation_name => 'example_span'
  );
  $span->log('test message ' . $_ . ' from the parent') for 1..3;
  my $child = $span->span(operation_name => 'child_span');
  $child->log('message ' . $_ . ' from the child span') for 1..3;
 }
 # Make sure all trace data is sent
 $tracing->sync->get;

You should then see a trace with 2 spans show up.

=cut

use mro;
use curry;
use Syntax::Keyword::Try;
use Time::HiRes ();
use IO::Async::Socket;
use Future::AsyncAwait;

use OpenTracing;
use OpenTracing::Batch;
use OpenTracing::Protocol::Jaeger;
use OpenTracing::Any qw($tracer);

use Log::Any qw($log);

=head2 configure

Takes the following named parameters:

=over 4

=item * C<host> - where to send traces

=item * C<port> - the UDP/TCP port to connect to

=item * C<protocol> - how to communicate: thrift, http/thrift, etc.

=item * C<items_per_batch> - number of spans to try sending each time

=item * C<batches_per_loop> - number of batches to try sending for each loop iteration

=item * C<tracer> - the L<OpenTracing::Tracer> instance to use, defaults to the one
provided by L<OpenTracing::Any>

=back

=cut

sub configure {
    my ($self, %args) = @_;
    $self->{pending} //= [];

    # Only support Jæger for now
    die 'invalid protocol' if $args{protocol} and $args{protocol} ne 'jaeger';

    for my $k (qw(host port protocol items_per_batch batches_per_loop tracer)) {
        $self->{$k} = delete $args{$k} if exists $args{$k};
    }
    return $self->next::method(%args);
}

=head2 host

The hostname or IP to send spans to.

=cut

sub host { shift->{host} }

=head2 port

The port to send spans to.

=cut

sub port { shift->{port} }

=head2 tracer

The L<OpenTracing::Tracer> instance, defaults to the standard L<OpenTracing::Any>-provided one.

=cut

sub tracer { shift->{tracer} || $tracer }

sub _add_to_loop {
    my ($self) = @_;

    # Nothing to send yet, so mark this as done immediately
    $self->{send_in_progress} = Future->done;

    $self->add_child(
        $self->{udp} = my $client = IO::Async::Socket->new(
            on_recv => sub {
                my ($sock, $payload, $addr) = @_;
                try {
                    $log->warnf("Receiving [%s] from %s - unexpected, this should be one-way opentracing traffic from us?", $payload, $addr);
                } catch {
                    $log->errorf("Exception when receiving: %s", $@);
                }
            },
            on_outgoing_empty => $self->$curry::weak(sub {
                shift->{send_in_progress}->done
            }),
        )
    );
    $self->tracer->add_span_completion_callback(
        $self->{span_completion} = $self->$curry::weak(sub {
            my ($self) = @_;
            $self->loop->later(sub {
                $self->start_sending;
            });
        })
    );
    $self->tracer->enable;
    $self->{connected} = $client->connect(
        host     => $self->host,
        service  => $self->port,
        socktype => 'dgram',
    )->on_done(sub {
        $log->tracef('Connected to UDP endpoint');
        $self->start_sending;
    })->retain;
}

=head1 METHODS - Internal

=head2 send

Performs the send and sets up the L<Future> for marking completion.

=cut

sub send {
    my ($self, $bytes) = @_;
    $self->{send_in_progress} = $self->loop->new_future
        if $self->{send_in_progress}->is_ready;
    $self->udp->send($bytes);
    return $self->send_in_progress;
}

=head2 send_in_progress

Returns a L<Future> indicating whether a send is in progress or not (will
be marked as L<Future/done> if the send is complete).

=cut

sub send_in_progress { shift->{send_in_progress}->without_cancel }

=head2 is_sending

Returns true if we are currently sending data.

=cut

sub is_sending { my $f = shift->{is_sending}; $f && !$f->is_ready }

=head2 start_sending

Trigger the send process, which will cause all pending traces to be
sent to the remote endpoint.

Does nothing if sending is already in progress.

=cut

sub start_sending {
    my ($self) = @_;
    return if $self->is_sending;
    $self->{is_sending} = $self->send_all_pending;
}

=head2 proto

The L<OpenTracing::Protocol> instance.

=cut

sub proto { shift->{proto} //= OpenTracing::Protocol::Jaeger->new }

=head2 sub

Sends all pending batches.

=cut

async sub send_all_pending {
    my ($self) = @_;
    my $count = 0;
    while(await $self->send_next_batch) {
        await $self->loop->delay_future(after => 0)
            unless ++$count % $self->batches_per_loop;
    }
}

sub items_per_batch { shift->{items_per_batch} ||= 10 }
sub batches_per_loop { shift->{batches_per_loop} ||= 64 }

=head2 sub

Gathers and sends a single L<OpenTracing::Batch>.

=cut

async sub send_next_batch {
    my ($self) = @_;
    my $batch = OpenTracing::Batch->new;
    my @spans = $self->tracer->extract_finished_spans($self->items_per_batch)
        or return 0;
    $batch->add_span($_) for @spans;

    my $bytes = pack('n1n1N/a*N1', 0x8001, 4, 'emitBatch', 1)
        . $self->proto->encode_batch($batch)
        . pack('C1', 0);
    await $self->send(
        $bytes
    );
    return 0 + @spans;
}

=head2 span_completion

Our callback for reporting span completion.

=cut

sub span_completion { shift->{span_completion} }

sub _remove_from_loop {
    my ($self) = @_;
    my $span_completion = $self->span_completion or return;
    $self->tracer->remove_span_completion_callback($span_completion);
}

=head2 udp

The remote UDP endpoint (if it exists).

=cut

sub udp { shift->{udp} }

=head2 sync

Ensure that we've sent any remaining traces. Can be called just before shutdown
to clear off any pending items - this returns a L<Future>, so you'd want code
similar to

 $tracing->sync->get;

to ensure that it completes before returning.

=cut

sub sync {
    my ($self) = @_;
    return $self->{connected}->then(async sub {
        await $self->send_all_pending;
    });
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2018-2020. Licensed under the same terms as Perl itself.

