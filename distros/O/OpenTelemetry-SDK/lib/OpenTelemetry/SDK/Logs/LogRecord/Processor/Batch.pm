use Object::Pad ':experimental(init_expr)';
# ABSTRACT: A batched OpenTelemetry log record processor

package OpenTelemetry::SDK::Logs::LogRecord::Processor::Batch;

our $VERSION = '0.101';

class OpenTelemetry::SDK::Logs::LogRecord::Processor::Batch
    :isa(OpenTelemetry::Processor::Batch)
    :does(OpenTelemetry::Logs::LogRecord::Processor)
{
    use Feature::Compat::Try;
    use OpenTelemetry::Constants -export;
    use OpenTelemetry;

    use Metrics::Any '$metrics', strict => 1,
        name_prefix => [qw( otel processor batch )];

    $metrics->make_counter( 'failure',
        description => 'Number of times the log processing pipeline failed irrecoverably',
    );

    $metrics->make_counter( 'success',
        description => 'Number of logs that were successfully processed',
    );

    $metrics->make_counter( 'dropped',
        name        => [qw( logs dropped )],
        description => 'Number of logs that could not be processed and were dropped',
        labels      => [qw( reason )],
    );

    $metrics->make_counter( 'processed',
        name        => [qw( logs processed )],
        description => 'Number of logs that were successfully processed',
    );

    # FIXME: Experimenting here with different metric names.
    # This is probably something we are going to have to do
    # sooner or later, because the ones we copied from Ruby
    # are incompatible with eg. Prometheus.
    # Note that these are _not_ the same metrics that are
    # proposed on the specification issue, but these seem to
    # make sense for now.
    method report_dropped ( $reason, $count ) {
        $metrics->inc_counter_by( dropped => $count => [ reason => $reason ] );
        $self;
    }

    method report_result ( $result, $count ) {
        if ( $result == EXPORT_RESULT_SUCCESS ) {
            $metrics->inc_counter('success');
            $metrics->inc_counter_by( processed => $count );
            return $self;
        }

        $metrics->inc_counter('failure');
        $self->report_dropped( 'export-failure' => $count );
    }

    method on_emit ($log) {
        return if $self->done;
        $self->process($log);
        return;
    }
}
