use Object::Pad ':experimental(init_expr)';
# ABSTRACT: An OpenTelemetry span exporter that prints to the console

package OpenTelemetry::SDK::Exporter::Console;

our $VERSION = '0.025';

class OpenTelemetry::SDK::Exporter::Console
    :does(OpenTelemetry::Exporter)
{
    use Future::AsyncAwait;
    use OpenTelemetry::Constants -trace_export;

    use feature 'say';

    field $handle :param = \*STDERR;
    field $stopped;

    my sub dump_event ($event) {
        {
            timestamp          => $event->timestamp,
            name               => $event->name,
            attributes         => $event->attributes,
            dropped_attributes => $event->dropped_attributes,
        }
    }

    my sub dump_link ($link) {
        {
            trace_id           => $link->context->hex_trace_id,
            span_id            => $link->context->hex_span_id,
            attributes         => $link->attributes,
            dropped_attributes => $link->dropped_attributes,
        }
    }

    my sub dump_status ($status) {
        {
            code        => $status->code,
            description => $status->description,
        }
    }

    my sub dump_scope ($scope) {
        {
            name    => $scope->name,
            version => $scope->version,
        }
    }

    method export ( $spans, $timeout = undef ) {
        return TRACE_EXPORT_FAILURE if $stopped;

        require Data::Dumper;
        local $Data::Dumper::Indent   = 0;
        local $Data::Dumper::Terse    = 1;
        local $Data::Dumper::Sortkeys = 1;

        for my $span (@$spans) {
            my $resource = $span->resource;

            say $handle Data::Dumper::Dumper({
                attributes            => $span->attributes,
                end_timestamp         => $span->end_timestamp,
                events                => [ map dump_event($_), $span->events ],
                instrumentation_scope => dump_scope($span->instrumentation_scope),
                kind                  => $span->kind,
                links                 => [ map dump_link($_), $span->links ],
                name                  => $span->name,
                parent_span_id        => $span->hex_parent_span_id,
                resource              => $resource ? $resource->attributes : {},
                span_id               => $span->hex_span_id,
                start_timestamp       => $span->start_timestamp,
                status                => dump_status($span->status),
                dropped_attributes    => $span->dropped_attributes,
                dropped_events        => $span->dropped_events,
                dropped_links         => $span->dropped_links,
                trace_flags           => $span->trace_flags->flags,
                trace_id              => $span->hex_trace_id,
                trace_state           => $span->trace_state->to_string,
            });
        }

        TRACE_EXPORT_SUCCESS;
    }

    async method shutdown ( $timeout = undef ) {
        $stopped = 1;
        TRACE_EXPORT_SUCCESS;
    }

    async method force_flush ( $timeout = undef ) { TRACE_EXPORT_SUCCESS }
}
