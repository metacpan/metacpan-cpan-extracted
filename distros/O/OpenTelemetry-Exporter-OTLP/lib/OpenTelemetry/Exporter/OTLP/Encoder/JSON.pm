use Object::Pad ':experimental(init_expr)';
# ABSTRACT: A JSON encoder for the OTLP exporter

package OpenTelemetry::Exporter::OTLP::Encoder::JSON;

our $VERSION = '0.017';

class OpenTelemetry::Exporter::OTLP::Encoder::JSON {
    use JSON::MaybeXS;
    use OpenTelemetry::Constants 'HEX_INVALID_SPAN_ID';
    use Ref::Util qw( is_hashref is_arrayref );
    use Scalar::Util 'refaddr';

    use experimental 'isa';

    method content_type () { 'application/json' }

    method serialise ($data) { encode_json $data }

    method encode_arraylist ($v) {
        [ map $self->encode_anyvalue($_), @$v ]
    }

    method encode_kvlist ($v) {
        [
            map {
                {
                    key   => $_,
                    value => $self->encode_anyvalue( $v->{$_} )
                }
            } keys %$v
        ]
    }

    method encode_anyvalue ( $v ) {
        return { kvlistValue => { values => $self->encode_kvlist($v) } }
            if is_hashref $v;

        return { arrayValue  => { values => $self->encode_arraylist($v) } }
            if is_arrayref $v;

        if ( my $ref = ref $v ) {
            warn "Unsupported ref while encoding: $ref";
            return;
        }

        # TODO: not strings
        return { stringValue => "$v" };
    }

    method encode_resource ( $resource ) {
        {
            attributes             => $self->encode_kvlist($resource->attributes),
            droppedAttributesCount => $resource->dropped_attributes,
        };
    }

    method encode_span_event ( $event ) {
        {
            attributes             => $self->encode_kvlist($event->attributes),
            droppedAttributesCount => $event->dropped_attributes,
            name                   => $event->name,
            timeUnixNano           => int $event->timestamp * 1_000_000_000,
        };
    }

    method encode_span_link ( $link ) {
        {
            attributes             => $self->encode_kvlist($link->attributes),
            droppedAttributesCount => $link->dropped_attributes,
            spanId                 => $link->context->hex_span_id,
            traceId                => $link->context->hex_trace_id,
        };
    }

    method encode_span_status ( $status ) {
        {
            code    => $status->code,
            message => '' . $status->description,
        };
    }

    method encode_span ( $span ) {
        my $data = {
            attributes             => $self->encode_kvlist($span->attributes),
            droppedAttributesCount => $span->dropped_attributes,
            droppedEventsCount     => $span->dropped_events,
            droppedLinksCount      => $span->dropped_links,
            endTimeUnixNano        => int $span->end_timestamp * 1_000_000_000,
            events                 => [ map $self->encode_span_event($_), $span->events ],
            kind                   => $span->kind,
            links                  => [ map $self->encode_span_link($_),  $span->links  ],
            name                   => $span->name,
            spanId                 => $span->hex_span_id,
            startTimeUnixNano      => int $span->start_timestamp * 1_000_000_000,
            status                 => $self->encode_span_status($span->status),
            traceId                => $span->hex_trace_id,
            traceState             => $span->trace_state->to_string,
        };

        my $parent = $span->hex_parent_span_id;
        $data->{parentSpanId} = $parent
            unless $parent eq HEX_INVALID_SPAN_ID;

        $data;
    }

    method encode_log ( $log ) {
        my $data = {
            attributes             => $self->encode_kvlist($log->attributes),
            body                   => $self->encode_anyvalue($log->body),
            droppedAttributesCount => $log->dropped_attributes,
            flags                  => $log->trace_flags->flags,
            observedTimeUnixNano   => int $log->observed_timestamp * 1_000_000_000,
            severityNumber         => $log->severity_number,
            severityText           => $log->severity_text,
            spanId                 => $log->hex_span_id,
            traceId                => $log->hex_trace_id,
        };

        my $t = $log->timestamp;
        $data->{timeUnixNano} = int $t * 1_000_000_000 if defined $t;

        $data;
    }

    method encode_scope ( $scope ) {
        {
            attributes             => $self->encode_kvlist($scope->attributes),
            droppedAttributesCount => $scope->dropped_attributes,
            name                   => $scope->name,
            version                => $scope->version,
        };
    }

    method encode_scope_spans ( $scope, $spans ) {
        {
            scope => $self->encode_scope($scope),
            spans => [ map $self->encode_span($_), @$spans ],
        };
    }

    method encode_scope_logs ( $scope, $logs ) {
        {
            scope      => $self->encode_scope($scope),
            logRecords => [ map $self->encode_log($_), @$logs ],
        };
    }

    method encode_resource_spans ( $resource, $spans ) {
        my %scopes;

        for (@$spans) {
            my $key = refaddr $_->instrumentation_scope;

            $scopes{ $key } //= [ $_->instrumentation_scope, [] ];
            push @{ $scopes{ $key }[1] }, $_;
        }

        {
            resource   => $self->encode_resource($resource),
            scopeSpans => [ map $self->encode_scope_spans(@$_), values %scopes ],
            schemaUrl  => $resource->schema_url,
        };
    }

    method encode_resource_logs ( $resource, $logs ) {
        my %scopes;

        for (@$logs) {
            my $key = refaddr $_->instrumentation_scope;

            $scopes{ $key } //= [ $_->instrumentation_scope, [] ];
            push @{ $scopes{ $key }[1] }, $_;
        }

        {
            resource  => $self->encode_resource($resource),
            scopeLogs => [ map $self->encode_scope_logs(@$_), values %scopes ],
            schemaUrl => $resource->schema_url,
        };
    }

    method encode ( $data ) {
        my ( %request, %resources );

        my $type;
        for (@$data) {
            $type //= $_ isa OpenTelemetry::SDK::Logs::LogRecord
                ? 'logs'
                : 'spans';

            my $key = refaddr $_->resource;
            $resources{ $key } //= [ $_->resource, [] ];
            push @{ $resources{ $key }[1] }, $_;
        }

        my $encode = "encode_resource_$type";
        $self->serialise({
            'resource' . ucfirst $type => [
                map $self->$encode(@$_), values %resources,
            ]
        });
    }
}
