use Object::Pad ':experimental(init_expr)';
# ABSTRACT: A batched OpenTelemetry processor

package OpenTelemetry::Processor::Batch;

our $VERSION = '0.100';

# TODO: If we move the different base implementations of processors
# to the top-level, that still leaves the specific implementations
# for Traces / Metrics / Logs to exist somewhere else.
# This works, although we need to be careful about clarifying what
# the expectations are for classes in each namespace, and the what
# are the interfaces they expose.
# In all honesty, this separation ended up looking a lot better than
# expected.
class OpenTelemetry::Processor::Batch :does(OpenTelemetry::Processor) {
    use Feature::Compat::Defer;
    use Feature::Compat::Try;
    use Future::AsyncAwait;
    use IO::Async::Function;
    use IO::Async::Loop;
    use Mutex;
    use OpenTelemetry::Common qw( config timeout_timestamp maybe_timeout );
    use OpenTelemetry::Constants -export;
    use OpenTelemetry::X;
    use OpenTelemetry;

    my $logger = OpenTelemetry::Common::internal_logger;

    use Metrics::Any '$metrics', strict => 1,
        name_prefix => [qw( otel processor batch )];

    $metrics->make_gauge( 'buffer_use',
        name        => [qw( buffer use )],
        description => 'Ratio between maximum queue size and the size of the queue at export time',
    );

    field $batch_size       :param //= config('BSP_MAX_EXPORT_BATCH_SIZE') //    512;
    field $exporter_timeout :param //= config('BSP_EXPORT_TIMEOUT')        // 30_000;
    field $max_queue_size   :param //= config('BSP_MAX_QUEUE_SIZE')        //  2_048;
    field $schedule_delay   :param //= config('BSP_SCHEDULE_DELAY')        //  5_000;
    field $exporter         :param;

    field $lock = Mutex->new;

    field $done :reader;
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

    method process ( @items ) {
        try {
            my $batch = $lock->enter(
                sub {
                    my $overflow = @queue + @items - $max_queue_size;
                    if ( $overflow > 0 ) {
                        # If the buffer is full, we drop old spans first
                        # The queue is always FIFO, even for dropped spans
                        # This behaviour is not in the spec, but is
                        # consistent with the Ruby implementation.
                        # For context, the Go implementation instead
                        # blocks until there is room in the buffer.
                        splice @queue, 0, $overflow;
                        $self->report_dropped( 'buffer-full', $overflow );
                    }

                    push @queue, @items;

                    return [] if @queue < $batch_size;

                    $metrics->set_gauge_to(
                        buffer_use => @queue / $max_queue_size
                    ) if @queue;

                    [ splice @queue, 0, $batch_size ];
                }
            );

            return unless @$batch;

            # Make sure we call this in void context so we don't have
            # to wait for the future ourselves
            $function->call(
                args => [ $exporter, $batch, $exporter_timeout ],
                on_result => sub ( $type, $result ) {
                    my $count = scalar @$batch;

                    return $self->report_result( EXPORT_RESULT_FAILURE, $count )
                        unless $type eq 'return';

                    $self->report_result( $result, $count );
                },
            );

            return;
        }
        catch($e) {
            warn $e;
        }
    }

    method report_dropped ( $reason, $count ) { $self }

    method report_result ( $result, $count ) { $result }

    async method shutdown ( $timeout = undef ) {
        return EXPORT_RESULT_SUCCESS if $done;

        $done = 1;

        my $start = timeout_timestamp;

        # TODO: The Ruby implementation ignores whether the force_flush
        # times out. Is this correct?
        await $self->force_flush( maybe_timeout $timeout, $start );

        $self->report_dropped( 'terminating', scalar @queue ) if @queue;
        @queue = ();

        await $function->stop if $function->workers;

        await $exporter->shutdown( maybe_timeout $timeout, $start );
    }

    async method force_flush ( $timeout = undef ) {
        return EXPORT_RESULT_SUCCESS if $done;

        my $start = timeout_timestamp;

        my @stack = $lock->enter( sub { splice @queue, 0, @queue } );

        defer {
            # If we still have any spans left it has to be because we
            # timed out and couldn't export them. In that case, we drop
            # them and report
            $self->report_dropped( 'force-flush', scalar @stack ) if @stack;
        }

        while ( @stack ) {
            my $remaining = maybe_timeout $timeout, $start;
            return EXPORT_RESULT_TIMEOUT if $timeout and !$remaining;

            my $batch = [ splice @stack, 0, $batch_size ];

            my $count = scalar @$batch;
            try {
                my $result = await $function->call(
                    args => [ $exporter, $batch, $remaining ],
                );

                $self->report_result( $result, $count );

                return $result unless $result == EXPORT_RESULT_SUCCESS;
            }
            catch ($e) {
                return $self->report_result( EXPORT_RESULT_FAILURE, $count);
            }
        }

        await $exporter->force_flush( maybe_timeout $timeout, $start );
    }

    method DESTROY {
        try { $function->stop->get }
        catch ($e) { }
    }
}
