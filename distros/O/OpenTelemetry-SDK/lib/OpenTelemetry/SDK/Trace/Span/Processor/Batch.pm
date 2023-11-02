use Object::Pad ':experimental(init_expr)';
# ABSTRACT: A batched OpenTelemetry span processor

package OpenTelemetry::SDK::Trace::Span::Processor::Batch;

our $VERSION = '0.011';

class OpenTelemetry::SDK::Trace::Span::Processor::Batch
    :does(OpenTelemetry::Trace::Span::Processor)
{
    use Feature::Compat::Defer;
    use Feature::Compat::Try;
    use Future::AsyncAwait;
    use IO::Async::Function;
    use IO::Async::Loop;
    use Mutex;
    use OpenTelemetry::Common qw( config timeout_timestamp maybe_timeout );
    use OpenTelemetry::Constants -trace_export;
    use OpenTelemetry::X;
    use OpenTelemetry;

    use Metrics::Any '$metrics', strict => 0;
    my $logger = OpenTelemetry->logger;

    field $batch_size       :param //= config('BSP_MAX_EXPORT_BATCH_SIZE') //    512;
    field $exporter_timeout :param //= config('BSP_EXPORT_TIMEOUT')        // 30_000;
    field $max_queue_size   :param //= config('BSP_MAX_QUEUE_SIZE')        //  2_048;
    field $schedule_delay   :param //= config('BSP_SCHEDULE_DELAY')        //  5_000;
    field $exporter         :param;

    field $lock = Mutex->new;

    field $done;
    field $function;
    field @futures;
    field @queue;

    ADJUST {
        die OpenTelemetry::X->create(
            Invalid => "Exporter must implement the OpenTelemetry::Exporter interface: " . ( ref $exporter || $exporter )
        ) unless $exporter && $exporter->DOES('OpenTelemetry::Exporter');

        if ( $batch_size > $max_queue_size ) {
            OpenTelemetry->logger->warn(
                'Max export batch size cannot be greater than maximum queue size when instantiating batch processor',
                {
                    batch_size => $batch_size,
                    queue_size => $max_queue_size,
                },
            );
            $batch_size = $max_queue_size;
        }

        # This is a non-standard variable, so we make it Perl-specific
        my $max_workers = $ENV{OTEL_PERL_BSP_MAX_WORKERS};

        $function = IO::Async::Function->new(
            $max_workers ? ( max_workers => $max_workers ) : (),

            code => sub ( $exporter, $batch, $timeout ) {
                $exporter->export( $batch, $timeout );
            },
        );

        IO::Async::Loop->new->add($function);

        # TODO: Should this be made configurable? The Ruby SDK
        # allows users to not start the thread on boot, although
        # this is not standard
        $function->start;
    }

    method $report_dropped_spans ( $count, $reason ) {
        $metrics->inc_counter_by(
            'otel.bsp.dropped_spans' => $count, { reason => $reason },
        );
    }

    method $report_result ( $code, $batch ) {
        my $count = @$batch;

        if ( $code == TRACE_EXPORT_SUCCESS ) {
            $metrics->inc_counter('otel.bsp.export.success');
            $metrics->inc_counter_by( 'otel.bsp.exported_spans' => $count );
            return;
        }

        OpenTelemetry->handle_error(
            exception => sprintf(
                'Unable to export %s span%s', $count, $count ? 's' : ''
            ),
        );

        $metrics->inc_counter('otel.bsp.export.failure');
        $self->$report_dropped_spans( $count, 'export-failure' );
    }

    method $maybe_process_batch ( $force = undef ) {
        my $batch = $lock->enter(
            sub {
                return [] if @queue < $batch_size && !$force;

                $metrics->set_gauge_to(
                    'otel.bsp.buffer_utilization' => @queue / $max_queue_size,
                ) if @queue;

                [ map $_->snapshot, splice @queue, 0, $batch_size ];
            }
        );

        return unless @$batch;

        $function->call(
            args => [ $exporter, $batch, $exporter_timeout ],
            on_result => sub ( $type, $result ) {
                return $self->$report_result( TRACE_EXPORT_FAILURE, $batch )
                    unless $type eq 'return';

                $self->$report_result( $result, $batch );
            },
        );

        return;
    }

    method on_start ( $span, $context ) { }

    method on_end ($span) {
        return if $done;

        try {
            return unless $span->context->trace_flags->sampled;

            $lock->enter(
                sub {
                    my $overflow = @queue + 1 - $max_queue_size;
                    if ( $overflow > 0 ) {
                        # If the buffer is full, we drop old spans first
                        # The queue is always FIFO, even for dropped spans
                        # This behaviour is not in the spec, but is
                        # consistent with the Ruby implementation.
                        # For context, the Go implementation instead
                        # blocks until there is room in the buffer.
                        splice @queue, 0, $overflow;
                        $self->$report_dropped_spans(
                            $overflow,
                            'buffer-full',
                        );
                    }

                    push @queue, $span;
                }
            );

            $self->$maybe_process_batch;
        }
        catch ($e) {
            OpenTelemetry->handle_error(
                exception => $e,
                message   => 'unexpected error in ' . ref($self) . '->on_end',
            );
        }

        return;
    }

    async method shutdown ( $timeout = undef ) {
        return TRACE_EXPORT_SUCCESS if $done;

        $done = 1;

        my $start = timeout_timestamp;

        # TODO: The Ruby implementation ignores whether the force_flush
        # times out. Is this correct?
        await $self->force_flush( maybe_timeout $timeout, $start );

        $self->$report_dropped_spans( +@queue, 'terminating' ) if @queue;
        @queue = ();

        $function->stop->get if $function->workers;

        $exporter->shutdown( maybe_timeout $timeout, $start );
    }

    async method force_flush ( $timeout = undef ) {
        return TRACE_EXPORT_SUCCESS if $done;

        my $start = timeout_timestamp;

        my @stack = $lock->enter( sub { splice @queue, 0, @queue } );

        defer {
            # If we still have any spans left it has to be because we
            # timed out and couldn't export them. In that case, we drop
            # them and report
            $self->$report_dropped_spans( +@stack, 'force-flush' ) if @stack;
        }

        while ( @stack ) {
            my $remaining = maybe_timeout $timeout, $start;
            return TRACE_EXPORT_TIMEOUT if $timeout and !$remaining;

            my $batch = [ map $_->snapshot, splice @stack, 0, $batch_size ];

            try {
                my $result = await $function->call(
                    args => [ $exporter, $batch, $remaining ],
                );

                $self->$report_result( $result, $batch );

                return $result unless $result == TRACE_EXPORT_SUCCESS;
            }
            catch ($e) {
                return $self->$report_result( TRACE_EXPORT_FAILURE, $batch );
            }
        }

        $exporter->force_flush( maybe_timeout $timeout, $start );
    }

    method DESTROY {
        try { $function->stop->get }
        catch ($e) { }
    }
}
