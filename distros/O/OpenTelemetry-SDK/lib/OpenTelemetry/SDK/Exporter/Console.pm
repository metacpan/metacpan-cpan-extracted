use Object::Pad ':experimental(init_expr)';
# ABSTRACT: An OpenTelemetry span exporter that prints to the console

package OpenTelemetry::SDK::Exporter::Console;

our $VERSION = '0.101';

class OpenTelemetry::SDK::Exporter::Console
    :does(OpenTelemetry::Exporter)
{
    use Data::Dumper;
    use Future::AsyncAwait;
    use OpenTelemetry::Constants -trace_export;

    use isa qw(
        OpenTelemetry::SDK::Logs::LogRecord
        OpenTelemetry::SDK::Trace::Span::Readable
    );

    use feature 'say';

    field $encoder :param //= undef;
    field $handle  :param = \*STDERR;
    field $stopped;

    ADJUST {
        $encoder //= do {
            my ( $format, @options ) = split /,/,
                $ENV{OTEL_PERL_EXPORTER_CONSOLE_FORMAT} // 'data-dumper';

            my %options = map split( /=/, $_, 2 ), @options;

            if ( lc $format eq 'json' ) {
                require JSON::MaybeXS;
                my $json = JSON::MaybeXS->new(
                    # Defaults
                    canonical => 1,
                    utf8      => 1,

                    # User overrides
                    %options,
                );

                sub { $json->encode(@_) };
            }
            else {
                sub {
                    require Data::Dumper;

                    # Defaults
                    local $Data::Dumper::Indent   = 0;
                    local $Data::Dumper::Terse    = 1;
                    local $Data::Dumper::Sortkeys = 1;

                    my $dumper = Data::Dumper->new([@_]);
                    $dumper->$_( $options{$_} ) for keys %options;
                    $dumper->Dump;
                };
            }
        };
    }

    my sub dump_span_event ($event) {
        {
            timestamp          => $event->timestamp,
            name               => $event->name,
            attributes         => $event->attributes,
            dropped_attributes => $event->dropped_attributes,
        }
    }

    my sub dump_span_link ($link) {
        {
            trace_id           => $link->context->hex_trace_id,
            span_id            => $link->context->hex_span_id,
            attributes         => $link->attributes,
            dropped_attributes => $link->dropped_attributes,
        }
    }

    my sub dump_span_status ($status) {
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

    my sub dump_span ($span) {
        my $resource = $span->resource;
        return {
            attributes            => $span->attributes,
            dropped_attributes    => $span->dropped_attributes,
            dropped_events        => $span->dropped_events,
            dropped_links         => $span->dropped_links,
            end_timestamp         => $span->end_timestamp,
            events                => [ map dump_span_event($_), $span->events ],
            instrumentation_scope => dump_scope($span->instrumentation_scope),
            kind                  => $span->kind,
            links                 => [ map dump_span_link($_), $span->links ],
            name                  => $span->name,
            parent_span_id        => $span->hex_parent_span_id,
            resource              => $resource ? $resource->attributes : {},
            span_id               => $span->hex_span_id,
            start_timestamp       => $span->start_timestamp,
            status                => dump_span_status($span->status),
            trace_flags           => $span->trace_flags->flags,
            trace_id              => $span->hex_trace_id,
            trace_state           => $span->trace_state->to_string,
        };
    }

    my sub dump_log ($log) {
        my $resource = $log->resource;
        return {
            attributes            => $log->attributes,
            body                  => $log->body,
            dropped_attributes    => $log->dropped_attributes,
            flags                 => $log->trace_flags->flags,
            instrumentation_scope => dump_scope($log->instrumentation_scope),
            observed_timestamp    => $log->observed_timestamp,
            resource              => $resource ? $resource->attributes : {},
            severity_number       => 0+$log->severity_number,
            severity_text         => $log->severity_text,
            span_id               => $log->hex_span_id,
            timestamp             => $log->timestamp,
            trace_id              => $log->hex_trace_id,
        };
    }

    method export ( $batch, $timeout = undef ) {
        return TRACE_EXPORT_FAILURE if $stopped;

        for my $item (@$batch) {
            # FIXME: This multiple dispatch is annoying. We could move
            # this to different "export_$type"-style methods, but then
            # we would still need to be able to configure what method
            # to call (eg. in the batch exporter, the call to the function
            # is in the base class, not the metric-specific or log-specific
            # implementation). This might be tricky.
            # It might be that we want a placeholder LogRecord class in
            # the API distribution (like we have for spans) so we can
            # check for subclasses of that, and not require people to
            # subclass the SDK. This would allow other people to provide
            # their own implementations of a LogRecord as libraries too.
            # That seems like a reasonable plan.
            my $data;
            if ( isa_OpenTelemetry_SDK_Logs_LogRecord $item ) {
                $data = dump_log($item);
            }
            elsif ( isa_OpenTelemetry_SDK_Trace_Span_Readable $item ) {
                $data = dump_span($item);
            }

            chomp( my $encoded = $encoder->($data) );
            say $handle $encoded;
        }

        TRACE_EXPORT_SUCCESS;
    }

    async method shutdown ( $timeout = undef ) {
        $stopped = 1;
        TRACE_EXPORT_SUCCESS;
    }

    async method force_flush ( $timeout = undef ) { TRACE_EXPORT_SUCCESS }
}
