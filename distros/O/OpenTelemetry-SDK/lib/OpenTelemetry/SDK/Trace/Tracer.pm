use Object::Pad;
# ABSTRACT: A Tracer for the OpenTelemetry SDK

package OpenTelemetry::SDK::Trace::Tracer;

our $VERSION = '0.028';

class OpenTelemetry::SDK::Trace::Tracer :isa(OpenTelemetry::Trace::Tracer) {
    use OpenTelemetry::Constants 'SPAN_KIND_INTERNAL';
    use OpenTelemetry::Context;
    use OpenTelemetry::Trace;
    use OpenTelemetry::Common ();
    use Ref::Util 'is_hashref';

    field $span_creator :param;

    method create_span ( %args ) {
        $args{name} //= 'empty';
        $args{kind} //= SPAN_KIND_INTERNAL;

        unless (is_hashref( $args{attributes} // {} )) {
            OpenTelemetry::Common::internal_logger
                ->warn('The \'attributes\' parameter to create_span must be a hash reference, it was instead a ' . ( ref($args{attribute}) || 'plain scalar' ) );
            delete $args{attributes};
        }

        $args{context} = OpenTelemetry::Context->current
            unless exists $args{context};

        return $self->SUPER::create_span(%args)
            if OpenTelemetry::Trace->is_untraced_context($args{context});

        $span_creator->(%args);
    }
}
