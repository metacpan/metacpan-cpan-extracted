use Object::Pad ':experimental(init_expr)';
# ABSTRACT: A basic OpenTelemetry span processor

package OpenTelemetry::SDK::Trace::Span::Processor::Simple;

our $VERSION = '0.026';

class OpenTelemetry::SDK::Trace::Span::Processor::Simple
    :does(OpenTelemetry::Trace::Span::Processor)
{
    use Feature::Compat::Try;
    use Future::AsyncAwait;
    use OpenTelemetry::X;
    use OpenTelemetry;

    field $exporter :param;

    ADJUST {
        die OpenTelemetry::X->create(
            Invalid => "Exporter must implement the OpenTelemetry::Exporter interface: " . ( ref $exporter || $exporter )
        ) unless $exporter && $exporter->DOES('OpenTelemetry::Exporter');
    }

    method process ( @items ) {
        $exporter->export(\@items);
        return;
    }

    method on_start ( $span, $context ) { }

    method on_end ($span) {
        try {
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
        await $exporter->shutdown( $timeout );
    }

    async method force_flush ( $timeout = undef ) {
        await $exporter->force_flush( $timeout );
    }
}
