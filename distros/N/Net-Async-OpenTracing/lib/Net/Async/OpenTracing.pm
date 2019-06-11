package Net::Async::OpenTracing;
# ABSTRACT: wire protocol support for the opentracing.io API

use strict;
use warnings;

use utf8;

our $VERSION = '0.001';

use parent qw(IO::Async::Notifier);

=encoding utf8

=head1 NAME

Net::Async::OpenTracing - basic proof-of-concept implementation for OpenTracing APM

=head1 DESCRIPTION

This all relies on the abstract L<OpenTracing> interface, so that'd be
the first port of call for official documentation.

=head2 Setting up and testing

Start up a Jæger instance in Docker like so:

 docker run -d --name jaeger \
  -e COLLECTOR_ZIPKIN_HTTP_PORT=9411 \
  -p 5775:5775/udp \
  -p 6831:6831/udp \
  -p 6832:6832/udp \
  -p 5778:5778 \
  -p 16686:16686 \
  -p 14268:14268 \
  -p 9411:9411 \
  jaegertracing/all-in-one:1.12

Set up an L<Net::Async::OpenTracing> instance with those connection details:

 my $loop = IO::Async::Loop->new;
 $loop->add(
    my $tracing = Net::Async::OpenTracing->new(
        host => '127.0.0.1',
        port => 6832,
    )
 );
 {
  my $batch = $tracing->new_batch();
  my $span = $batch->new_span(
   'example_span'
  );
  $span->log('test message ' . $_ . ' from the parent') for 1..3;
  my $child = $span->new_span('child_span');
  $child->log('message ' . $_ . ' from the child span') for 1..3;
 }
 # Make sure all trace data is sent
 $tracing->sync->get;

You should then see a trace with 2 spans show up.

=cut

no indirect;

use Syntax::Keyword::Try;
use Unicode::UTF8 qw(encode_utf8 decode_utf8);
use Time::HiRes ();
use Math::Random::Secure;
use IO::Async::Socket;

use OpenTracing;

use Log::Any qw($log);

# The documentation is less clear on this than I'd like:
# - ordinal value of the list is presumably 0, but might also be 1,
# so we extract to a constant here
use constant ENUM_BASE => 0;

sub configure {
    my ($self, %args) = @_;
    $self->{pending} //= [];
    for my $k (qw(host port)) {
        $self->{$k} = delete $args{$k} if exists $args{$k};
    }
    return $self->next::method(%args);
}

sub host { shift->{host} }
sub port { shift->{port} }

sub _add_to_loop {
    my ($self) = @_;
    $self->add_child(
        $self->{udp} = my $client = IO::Async::Socket->new(
            on_recv => sub {
                my ($sock, $payload, $addr) = @_;
                try {
                    $log->warnf("Receiving [%s] from %s - unexpected, this should be one-way opentracing traffic from us?", $payload, $addr);
                } catch {
                    $log->errorf("Exception when sending: %s", $@);
                }
            },
        )
    );
    $self->{connected} = $client->connect(
        host     => $self->host,
        service  => $self->port,
        socktype => 'dgram',
    )->then(sub {
        $log->tracef('Connected to UDP endpoint');
        my @pending = splice $self->{pending}->@*;
        $log->tracef('Have %d messages to send', 0 + @pending);
        Future->wait_all(
            map { $client->send($_) } @pending
        )
    })->retain;
}

sub process {
    my ($self) = @_;
    $self->{process} //= do {
        OpenTracing::Process->new(
            name => "$0"
        )
    }
}

sub udp { shift->{udp} }

sub new_batch {
    my ($self, %args) = @_;
    $log->tracef('Creating new opentracing batch');
    return OpenTracing::Batch->new(
        process => $self->process,
        on_destroy => sub {
            $log->infof('Destroy for batch');
            $self->send_batch(shift);
        }
    );
}

sub send_batch {
    my ($self, $batch) = @_;
    $log->tracef('Will try to send batch %s', $batch);

    # We're collecting binary Thrift protocol data here, and will send via UDP.
    my $data = '';
    $data .= pack 'C1n1',
        12, # struct Batch
        1;  # field 1

    my $process = $batch->process;
    # Process
    $data .= pack 'C1n1 C1n1N/a*',
        12, # struct
        1, # field id 1 = Process
    # string serviceName
        11, # string
        1, # field ID 1 = serviceName
        encode_utf8($process->name // '');

    if(my $tags = $process->tags) {
        # list Tag
        $data .= pack 'C1n1 C1N1',
            15, # list
            2, # field ID 2
            12, # struct
            0 + keys %$tags if %$tags;
        for my $k (sort keys %$tags) {
            $data .= pack 'C1n1N/a* C1n1N1 C1n1N/a* C1',
                11, # type = string
                1, # field ID = 1
                encode_utf8($k // ''),
                8, # type = int32 (enum)
                2, # field ID = 2
                ENUM_BASE, # entry 0 is string
                11, # type = string
                3, # field ID = 3
                encode_utf8($tags->{$k} // ''),
                0; # EOF marker
        }
    }
    $data .= pack 'C1', 0; # EOF marker for process

    # list<Span>
    my @spans = $batch->span_list;
    $data .= pack 'C1n1C1N1',
        15,
        2,
        12, # 12 is struct
        0 + @spans;
    for my $span (@spans) {
        $data .= pack 'CnQ> CnQ> CnQ> CnQ> CnN/a* CnN CnQ> CnQ>',
            # trace_id_low
            10,
            1,
            $span->trace_id,
            # trace_id_high
            10,
            2,
            0, # Math::Random::Secure::irand(2**62),
            # span_id
            10,
            3,
            $span->id,
            # parent_span_id
            10,
            4,
            $span->parent_id,
            # operation_name
            11,
            5,
            encode_utf8($span->operation_name // ''),
            # references
            # flags
            8,
            7,
            $span->flags // 0,
            # start_time
            10,
            8,
            $span->start_time,
            # duration
            10,
            9,
            $span->duration;
            # tags
        if(my $tags = $span->tags) {
            # list Tag
            $data .= pack 'C1n1 C1N1',
                15, # list
                10, # field ID 2 (?? why 10 then?)
                12, # struct
                0 + keys %$tags if %$tags;
            for my $k (sort keys %$tags) {
                $data .= pack 'C1n1N/a* C1n1N1 C1n1N/a* C1',
                    11, # type = string
                    1, # field ID = 1
                    encode_utf8($k // ''),
                    8, # type = int32 (enum)
                    2, # field ID = 2
                    ENUM_BASE, # entry 0 is string
                    11, # type = string
                    3, # field ID = 3
                    encode_utf8($tags->{$k} // ''),
                    0; # EOF marker
            }
        }
        if(my @logs = $span->log_list) {
            # list Log
            $data .= pack 'C1n1 C1N1',
                15, # list
                11, # field ID 11 for logs
                12, # struct
                0 + @logs;
            for my $log (@logs) {
                my $tags = $log->tags;
                $data .= pack 'C1n1Q> C1n1 C1N1',
                    10, # type = int64
                    1, # field ID = 1
                    $log->timestamp,
                    15, # list
                    2, # field ID 2
                    12, # list of structs
                    0 + keys %$tags if %$tags;
                for my $k (sort keys %$tags) {
                    $data .= pack 'C1n1N/a* C1n1N1 C1n1N/a* C1',
                        11, # type = string
                        1, # field ID = 1
                        encode_utf8($k),
                        8, # type = int32 (enum)
                        2, # field ID = 2
                        ENUM_BASE, # entry 0 is string
                        11, # type = string
                        3, # field ID = 3
                        encode_utf8($tags->{$k} // ''),
                        0; # EOF marker
                }
                $data .= pack 'C1', 0; # EOF for log
            }
        }

        $data .= pack 'C1', 0; # EOF for span
    }

    $data .= pack 'C1', 0; # EOF marker for Batch
    $data .= pack 'C1', 0; # EOF marker for method call

    # For the collector, we might want something like this:
    # my $msg = pack('n1n1N/a*N1', 0x8001, 1, 'submitBatches', 1) . $data;
    # but for UDP, we only get to talk to the agent, so it's a oneway emitBatch instead
    my $msg = pack('n1n1N/a*N1', 0x8001, 4, 'emitBatch', 1) . $data;
    if($self->{connected}->is_done) {
        $log->tracef('Sending packet now');
        $self->udp->send($msg, autoflush => 1);
    } else {
        $log->tracef('Defer packet until connection is ready');
        push $self->{pending}->@*, $msg;
    }
}

sub sync {
    my ($self) = @_;
    return $self->{connected}->then(sub {
        my $f = $self->loop->new_future;
        $self->udp->configure(
            on_outgoing_empty => sub { $f->done }
        );
        $f
    });
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2018-2019. Licensed under the same terms as Perl itself.

