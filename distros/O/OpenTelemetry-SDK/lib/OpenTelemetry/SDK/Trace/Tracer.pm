use Object::Pad;
# ABSTRACT: A Tracer for the OpenTelemetry SDK

package OpenTelemetry::SDK::Trace::Tracer;

our $VERSION = '0.011';

class OpenTelemetry::SDK::Trace::Tracer :isa(OpenTelemetry::Trace::Tracer) {
    use OpenTelemetry::Constants 'SPAN_KIND_INTERNAL';
    use OpenTelemetry::Context;
    use OpenTelemetry::Trace;

    field $span_creator :param;

    method create_span ( %args ) {
        $args{name} //= 'empty';
        $args{kind} //= SPAN_KIND_INTERNAL;

        $args{context} = OpenTelemetry::Context->current
            unless exists $args{context};

        return $self->SUPER::create_span(%args)
            if OpenTelemetry::Trace->is_untraced_context($args{context});

        $span_creator->(%args);
    }
}
