use Object::Pad ':experimental(init_expr)';
# ABSTRACT: An OpenTelemetry span exporter that prints to the console

package OpenTelemetry::SDK::Exporter::Console;

our $VERSION = '0.028';

class OpenTelemetry::SDK::Exporter::Console
    :does(OpenTelemetry::Exporter)
{
    use Future::AsyncAwait;
    use OpenTelemetry::Constants -trace_export;

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


        for my $span (@$spans) {
            my $resource = $span->resource;

            my $encoded = $encoder->({
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
            chomp $encoded;
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
