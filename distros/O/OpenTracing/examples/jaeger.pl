#!/usr/bin/env perl 
use strict;
use warnings;

use Future::AsyncAwait;
use Syntax::Keyword::Try;
use IO::Async::Loop;
use IO::Async::Socket;
use Net::Address::IP::Local;

use OpenTracing::Protocol::Jaeger;
use OpenTracing::Batch;
use OpenTracing::Span;
use OpenTracing::Integration qw(HTTP::Tiny System);
use OpenTracing::DSL qw(:v1);
use OpenTracing::Any qw($tracer);

use Log::Any qw($log);
use Log::Any::Adapter qw(Stdout), log_level => 'info';

# Normally you'd use Net::Async::OpenTracing or Net::OpenTracing
# to do the sending - this is a simple example demonstrating
# how you could implement that part yourself
my $loop = IO::Async::Loop->new;
my $socket = IO::Async::Socket->new(
	on_recv => sub {
		my ( $self, $dgram, $addr ) = @_;

		warn "Unexpected incoming reply on opentracing UDP port - $dgram\n",
		$loop->stop;
	},
	on_recv_error => sub {
		my ( $self, $errno ) = @_;
		die "Cannot recv - $errno\n";
	},
	on_outgoing_empty => sub {
		$log->infof('Outgoing buffer now empty');
		$loop->stop;
	},
);
$loop->add( $socket );

$socket->connect(
	host     => 'localhost',
	service  => 6832,
	socktype => 'dgram',
)->get;

$log->infof('Create initial span');
my $span = $tracer->span(
    operation_name => 'new_test_code'
);
$span->tag(xyz => 'abc');
Time::HiRes::sleep(0.05);
$log->infof('Create nested span');
my $sub = $span->new_span('secondary');
Time::HiRes::sleep(0.02);
$sub->tag(
    something => 'here'
);
$sub->log('message here');
$sub->finish;
$log->infof('Create Future-based span');
my $fs = $tracer->span_for_future(
    my $f = $loop->delay_future(after => 0.01)->set_label('example_future')
);
$f->get;
$span->finish;

$log->infof('Create span via OpenTracing::DSL');
trace {
    my ($span) = @_;
    $span->tag(some_key => 'some_value');
    Time::HiRes::sleep(0.01);
} operation_name => 'dsl_example';

$log->infof('Create span via HTTP::Tiny integration');
HTTP::Tiny->new->get('http://localhost');

$log->infof('Create span via System integration');
system('echo Created span via System integration');

$log->infof('Inject span for Context Propagation');
my $span_for_context = $tracer->span(operation_name => "span_context");
my $payload = $tracer->inject($span_for_context);

$log->infof('Extract span for Context Propagation');
my $span_context = $tracer->extract($payload);
my $span_with_context = $tracer->span(operation_name => "span_with_context", references => [$tracer->child_of($span_context)]);
$span_with_context->finish;
$span_for_context->finish;

$log->infof('Populating batch');
my $batch = OpenTracing::Batch->new;
$batch->add_span($_) for $tracer->extract_finished_spans(0);

$log->infof('Encoding batch');
my $proto = OpenTracing::Protocol::Jaeger->new;
my $bytes = pack('n1n1N/a*N1', 0x8001, 4, 'emitBatch', 1) . $proto->encode_batch($batch) . pack('C1', 0);
$log->infof('Sending %d bytes', length($bytes));
$socket->send(
    $bytes
);
$log->infof('Waiting');
$loop->run;

