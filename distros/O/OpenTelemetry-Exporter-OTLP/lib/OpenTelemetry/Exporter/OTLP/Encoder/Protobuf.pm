use Object::Pad ':experimental(init_expr)';
# ABSTRACT: A Protobuf encoder for the OTLP exporter

package OpenTelemetry::Exporter::OTLP::Encoder::Protobuf;

our $VERSION = '0.018';

class OpenTelemetry::Exporter::OTLP::Encoder::Protobuf
    :isa(OpenTelemetry::Exporter::OTLP::Encoder::JSON) {

    use OpenTelemetry::Constants 'INVALID_SPAN_ID';
    use OpenTelemetry::Proto;
    use Ref::Util qw( is_hashref is_arrayref );
    use Scalar::Util 'refaddr';

    method content_type () { 'application/x-protobuf' }

    method serialise ($data) {
        return OpenTelemetry::Proto::Collector::Logs::V1::ExportLogsServiceRequest
            ->new_and_check({ resource_logs => $data->{resourceLogs} })->encode
            if $data->{resourceLogs};

        return OpenTelemetry::Proto::Collector::Trace::V1::ExportTraceServiceRequest
            ->new_and_check({ resource_spans => $data->{resourceSpans} })->encode
            if $data->{resourceSpans};

        die 'Unknown payload type';
    }

    method encode_anyvalue ( $v ) {
        return { kvlist_value => { values => $self->encode_kvlist($v) } }
            if is_hashref $v;

        return { array_value  => { values => $self->encode_arraylist($v) } }
            if is_arrayref $v;

        if ( my $ref = ref $v ) {
            warn "Unsupported ref while encoding: $ref";
            return;
        }

        # TODO: not strings
        return { string_value => "$v" };
    }

    method encode_resource ( $resource ) {
        {
            attributes               => $self->encode_kvlist($resource->attributes),
            dropped_attributes_count => $resource->dropped_attributes,
        };
    }

    method encode_span_event ( $event ) {
        {
            attributes               => $self->encode_kvlist($event->attributes),
            dropped_attributes_count => $event->dropped_attributes,
            name                     => $event->name,
            time_unix_nano           => int $event->timestamp * 1_000_000_000,
        };
    }

    method encode_span_link ( $link ) {
        {
            attributes               => $self->encode_kvlist($link->attributes),
            dropped_attributes_count => $link->dropped_attributes,
            span_id                  => $link->context->span_id,
            trace_id                 => $link->context->trace_id,
        };
    }

    method encode_span ( $span ) {
        my $data = {
            attributes               => $self->encode_kvlist($span->attributes),
            dropped_attributes_count => $span->dropped_attributes,
            dropped_events_count     => $span->dropped_events,
            dropped_links_count      => $span->dropped_links,
            end_time_unix_nano       => int $span->end_timestamp * 1_000_000_000,
            events                   => [ map $self->encode_span_event($_), $span->events ],
            kind                     => $span->kind,
            links                    => [ map $self->encode_span_link($_),  $span->links  ],
            name                     => $span->name,
            span_id                  => $span->span_id,
            start_time_unix_nano     => int $span->start_timestamp * 1_000_000_000,
            status                   => $self->encode_span_status($span->status),
            trace_id                 => $span->trace_id,
            trace_state              => $span->trace_state->to_string,
        };

        my $parent = $span->parent_span_id;
        $data->{parent_span_id} = $parent
            unless $parent eq INVALID_SPAN_ID;

        $data;
    }

    method encode_log ( $log ) {
        my $data = {
            attributes               => $self->encode_kvlist($log->attributes),
            body                     => $self->encode_anyvalue( $log->body ),
            dropped_attributes_count => $log->dropped_attributes,
            flags                    => $log->trace_flags->flags,
            observed_time_unix_nano  => int $log->observed_timestamp * 1_000_000_000,
            severity_number          => 0+$log->severity_number,
            severity_text            => $log->severity_text,
            span_id                  => $log->span_id,
            trace_id                 => $log->trace_id,
        };

        my $t = $log->timestamp;
        $data->{time_unix_nano} = int $t * 1_000_000_000 if defined $t;

        $data;
    }

    method encode_scope ( $scope ) {
        {
            attributes               => $self->encode_kvlist($scope->attributes),
            dropped_attributes_count => $scope->dropped_attributes,
            name                     => $scope->name,
            version                  => $scope->version,
        };
    }

    method encode_scope_logs ( $scope, $logs ) {
        {
            scope       => $self->encode_scope($scope),
            log_records => [ map $self->encode_log($_), @$logs ],
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
            resource => $self->encode_resource($resource),
            scope_spans => [
                map $self->encode_scope_spans(@$_), values %scopes,
            ],
            schema_url => $resource->schema_url,
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
            resource => $self->encode_resource($resource),
            scope_logs => [
                map $self->encode_scope_logs(@$_), values %scopes,
            ],
            schema_url => $resource->schema_url,
        };
    }
}
