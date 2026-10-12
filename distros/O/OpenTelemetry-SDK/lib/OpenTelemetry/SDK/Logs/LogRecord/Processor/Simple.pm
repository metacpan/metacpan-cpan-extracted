use Object::Pad ':experimental(init_expr)';
# ABSTRACT: A basic OpenTelemetry log record processor

package OpenTelemetry::SDK::Logs::LogRecord::Processor::Simple;

our $VERSION = '0.100';

class OpenTelemetry::SDK::Logs::LogRecord::Processor::Simple
    :isa(OpenTelemetry::Processor::Simple)
    :does(OpenTelemetry::Logs::LogRecord::Processor)
{
    use Feature::Compat::Try;

    method on_emit ($log) {
        try {
            $self->process($log);
        }
        catch ($e) {
            # TODO: One consequence of using these classes for logging
            # and not just traces is that we are limited in our ability
            # to log things. For the time being, we are falling back to
            # plain warns, but it might be that we need to come up with
            # some sort of logging equivalent to the untraced_context
            # that was added to OpenTelemetry::Trace to disable traces
            # in the OTLP exporter, which uses HTTP::Tiny, and would
            # generate traces when exporting traces, etc.
            warn "ERROR: $e";
            # OpenTelemetry->handle_error(
            #     exception => $e,
            #     message   => 'unexpected error in ' . ref($self) . '->on_emit',
            # );
        }

        return;
    }
}
