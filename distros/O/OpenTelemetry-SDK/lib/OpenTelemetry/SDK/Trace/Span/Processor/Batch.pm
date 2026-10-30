use Object::Pad ':experimental(init_expr)';
# ABSTRACT: A batched OpenTelemetry span processor

package OpenTelemetry::SDK::Trace::Span::Processor::Batch;

our $VERSION = '0.101';

class OpenTelemetry::SDK::Trace::Span::Processor::Batch
    :isa(OpenTelemetry::Processor::Batch)
    :does(OpenTelemetry::Trace::Span::Processor)
{
    use OpenTelemetry::Common ();
    use OpenTelemetry::Constants -export;

    my $logger = OpenTelemetry::Common::internal_logger;

    use Metrics::Any '$metrics', strict => 1,
        name_prefix => [qw( otel processor batch )];

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

    method report_dropped ( $reason, $count ) {
        $metrics->inc_counter_by( dropped => $count => [ reason => $reason ] );
        $self;
    }

    method report_result ( $result, $count ) {
        if ( $result == EXPORT_RESULT_SUCCESS ) {
            $metrics->inc_counter('success');
            $metrics->inc_counter_by( processed => $count );
        }
        else {
            $metrics->inc_counter('failure');
            $self->report_dropped( 'export-failure' => $count );
        }

        return $result;
    }

    method on_start ( $span, $context ) { }

    method on_end ($span) {
        return if $self->done;
        return unless $span->context->trace_flags->sampled;
        $self->process( $span->snapshot );
    }
}
