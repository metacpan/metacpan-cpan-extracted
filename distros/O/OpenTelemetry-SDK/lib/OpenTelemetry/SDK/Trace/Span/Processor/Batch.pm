use Object::Pad ':experimental(init_expr)';
# ABSTRACT: A batched OpenTelemetry span processor

package OpenTelemetry::SDK::Trace::Span::Processor::Batch;

our $VERSION = '0.028';

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

    my $logger = OpenTelemetry::Common::internal_logger;

    use Metrics::Any '$metrics', strict => 1,
        name_prefix => [qw( otel bsp )];

    $metrics->make_counter( 'failure',
        description => 'Number of times the span processing pipeline failed irrecoverably',
    );

    $metrics->make_counter( 'success',
        description => 'Number of spans that were successfully processed',
    );

    $metrics->make_counter( 'dropped',
        name        => [qw( spans dropped )],
        description => 'Number of spans that could not be processed and were dropped',
        labels      => [qw( reason )],
    );

    $metrics->make_counter( 'processed',
        name        => [qw( spans processed )],
        description => 'Number of spans that were successfully processed',
    );

    $metrics->make_gauge( 'buffer_use',
        name        => [qw( buffer utilization )],
        description => 'Number of spans that could not be processed and were dropped',
    );

    field $batch_size       :param //= config('BSP_MAX_EXPORT_BATCH_SIZE') //    512;
    field $exporter_timeout :param //= config('BSP_EXPORT_TIMEOUT')        // 30_000;
    field $max_queue_size   :param //= config('BSP_MAX_QUEUE_SIZE')        //  2_048;
    field $schedule_delay   :param //= config('BSP_SCHEDULE_DELAY')        //  5_000;
    field $exporter         :param;

    field $lock = Mutex->new;

    field $done;
    field $function;
    field @queue;

    ADJUST {
        die OpenTelemetry::X->create(
            Invalid => "Exporter must implement the OpenTelemetry::Exporter interface: " . ( ref $exporter || $exporter )
        ) unless $exporter && $exporter->DOES('OpenTelemetry::Exporter');

        if ( $batch_size > $max_queue_size ) {
            $logger->warn(
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
    }

    method $report_dropped_spans ( $reason, $count ) {
        $metrics->inc_counter_by( dropped => $count, [ reason => $reason ] );
    }

    method $report_result ( $code, $count ) {
        if ( $code == TRACE_EXPORT_SUCCESS ) {
            $metrics->inc_counter('success');
            $metrics->inc_counter_by( processed => $count );
            return;
        }

        OpenTelemetry->handle_error(
            exception => sprintf(
                'Unable to export %s span%s', $count, $count ? 's' : ''
            ),
        );

        $metrics->inc_counter('failure');
        $self->$report_dropped_spans( 'export-failure' => $count );
    }

    method process ( @items ) {
        my $batch = $lock->enter(
            sub {
                my $overflow = @queue + @items- $max_queue_size;
                if ( $overflow > 0 ) {
                    # If the buffer is full, we drop old spans first
                    # The queue is always FIFO, even for dropped spans
                    # This behaviour is not in the spec, but is
                    # consistent with the Ruby implementation.
                    # For context, the Go implementation instead
                    # blocks until there is room in the buffer.
                    splice @queue, 0, $overflow;
                    $self->$report_dropped_spans(
                        'buffer-full' => $overflow,
                    );
                }

                push @queue, @items;

                return [] if @queue < $batch_size;

                $metrics->set_gauge_to(
                    buffer_use => @queue / $max_queue_size,
                ) if @queue;

                [ splice @queue, 0, $batch_size ];
            }
        );

        return unless @$batch;

        $function->call(
            args => [ $exporter, $batch, $exporter_timeout ],
            on_result => sub ( $type, $result ) {
                my $count = @$batch;
                return $self->$report_result( TRACE_EXPORT_FAILURE, $count )
                    unless $type eq 'return';

                $self->$report_result( $result, $count );
            },
        );

        return;
    }

    method on_start ( $span, $context ) { }

    method on_end ($span) {
        try {
            return if $done;
            return unless $span->context->trace_flags->sampled;
            $self->process( $span->snapshot );
        }
        catch ($e) {
            OpenTelemetry->handle_error(
                exception => $e,
                message   => 'unexpected error in ' . ref($self) . '->on_end',
            );
        }
    }

    async method shutdown ( $timeout = undef ) {
        return TRACE_EXPORT_SUCCESS if $done;

        $done = 1;

        my $start = timeout_timestamp;

        # TODO: The Ruby implementation ignores whether the force_flush
        # times out. Is this correct?
        await $self->force_flush( maybe_timeout $timeout, $start );

        $self->$report_dropped_spans( terminating => scalar @queue )
            if @queue;

        @queue = ();

        $function->stop->get if $function->workers;

        await $exporter->shutdown( maybe_timeout $timeout, $start );
    }

    async method force_flush ( $timeout = undef ) {
        return TRACE_EXPORT_SUCCESS if $done;

        my $start = timeout_timestamp;

        my @stack = $lock->enter( sub { splice @queue, 0, @queue } );

        defer {
            # If we still have any spans left it has to be because we
            # timed out and couldn't export them. In that case, we drop
            # them and report
            $self->$report_dropped_spans( 'force-flush' => scalar @stack )
                if @stack;
        }

        while ( @stack ) {
            my $remaining = maybe_timeout $timeout, $start;
            return TRACE_EXPORT_TIMEOUT if $timeout and !$remaining;

            my $batch = [ splice @stack, 0, $batch_size ];
            my $count = @$batch;

            try {
                my $result = await $function->call(
                    args => [ $exporter, $batch, $remaining ],
                );

                $self->$report_result( $result, $count );

                return $result unless $result == TRACE_EXPORT_SUCCESS;
            }
            catch ($e) {
                return $self->$report_result( TRACE_EXPORT_FAILURE, $count );
            }
        }

        await $exporter->force_flush( maybe_timeout $timeout, $start );
    }

    method DESTROY {
        try { $function->stop->get }
        catch ($e) { }
    }
}
