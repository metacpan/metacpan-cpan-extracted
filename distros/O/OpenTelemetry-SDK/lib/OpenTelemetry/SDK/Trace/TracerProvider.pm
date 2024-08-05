use Object::Pad ':experimental(init_expr)';
# ABSTRACT: A TracerProvider for the OpenTelemetry SDK

package OpenTelemetry::SDK::Trace::TracerProvider;

our $VERSION = '0.024';

use OpenTelemetry;

class OpenTelemetry::SDK::Trace::TracerProvider :isa(OpenTelemetry::Trace::TracerProvider) {
    use Feature::Compat::Try;
    use Future::AsyncAwait;
    use List::Util 'any';
    use Mutex;
    use OpenTelemetry::Common qw( config timeout_timestamp maybe_timeout );
    use OpenTelemetry::Constants -trace_export;
    use OpenTelemetry::Propagator::TraceContext::TraceFlags;
    use OpenTelemetry::SDK::InstrumentationScope;
    use OpenTelemetry::SDK::Resource;
    use OpenTelemetry::SDK::Trace::Sampler::AlwaysOff;
    use OpenTelemetry::SDK::Trace::Sampler::AlwaysOn;
    use OpenTelemetry::SDK::Trace::Sampler::ParentBased;
    use OpenTelemetry::SDK::Trace::Sampler::TraceIDRatioBased;
    use OpenTelemetry::SDK::Trace::Span;
    use OpenTelemetry::SDK::Trace::SpanLimits;
    use OpenTelemetry::SDK::Trace::Tracer;
    use OpenTelemetry::Trace::SpanContext;

    use experimental 'isa';

    field $sampler      :param = undef;
    field $id_generator :param = 'OpenTelemetry::Trace';
    field $span_limits  :param //= OpenTelemetry::SDK::Trace::SpanLimits->new;
    field $resource     :param //= OpenTelemetry::SDK::Resource->new;
    field $stopped;
    field %registry;
    field @processors;

    field $lock          //= Mutex->new;
    field $registry_lock //= Mutex->new;

    ADJUST {
        try {
            for ( config('TRACES_SAMPLER') // 'parentbased_always_on' ) {
                $sampler //= OpenTelemetry::SDK::Trace::Sampler::AlwaysOn->new
                    if $_ eq 'always_on';

                $sampler //= OpenTelemetry::SDK::Trace::Sampler::AlwaysOff->new
                    if $_ eq 'always_off';

                $sampler //= OpenTelemetry::SDK::Trace::Sampler::TraceIDRatioBased->new(
                    ratio => config('TRACES_SAMPLER_ARG') // 1,
                ) if $_ eq 'traceidratio';

                $sampler //= OpenTelemetry::SDK::Trace::Sampler::ParentBased->new(
                    root => OpenTelemetry::SDK::Trace::Sampler::AlwaysOn->new,
                ) if $_ eq 'parentbased_always_on';

                $sampler //= OpenTelemetry::SDK::Trace::Sampler::ParentBased->new(
                    root => OpenTelemetry::SDK::Trace::Sampler::AlwaysOff->new,
                ) if $_ eq 'parentbased_always_off';

                $sampler //= OpenTelemetry::SDK::Trace::Sampler::ParentBased->new(
                    root => OpenTelemetry::SDK::Trace::Sampler::TraceIDRatioBased->new(
                        ratio => config('TRACES_SAMPLER_ARG') // 1,
                    ),
                ) if $_ eq 'parentbased_traceidratio';
            }
        }
        catch ($e) {
            my $default = OpenTelemetry::SDK::Trace::Sampler::ParentBased->new(
                root => OpenTelemetry::SDK::Trace::Sampler::AlwaysOn->new,
            );

            OpenTelemetry->handle_error(
                exception => $e,
                message   => 'installing default sampler ' . $default->description,
            );

            $sampler = $default;
        }
    }

    method $create_span (%args) {
        my %span = %args{qw( parent name kind start scope links resource )};

        $span{attribute_count_limit}  = $span_limits->attribute_count_limit;
        $span{attribute_length_limit} = $span_limits->attribute_length_limit;

        my $parent_span_context = OpenTelemetry::Trace
            ->span_from_context( $span{parent} )->context;

        my $trace_id = $parent_span_context->valid
            ? $parent_span_context->trace_id
            : $id_generator->generate_trace_id;

        my $result = $sampler->should_sample(
            trace_id   => $trace_id,
            context    => $args{parent},
            name       => $span{name},
            kind       => $span{kind},
            attributes => $args{attributes},
            links      => $span{links},
        );

        $span{attributes} = {
            %{ $args{attributes} // {} },
            %{ $result->attributes },
        };

        my $span_id = $id_generator->generate_span_id;

        if ( $result->recording && !$stopped ) {
            my $flags = $result->sampled
                ? OpenTelemetry::Propagator::TraceContext::TraceFlags->new(1)
                : OpenTelemetry::Propagator::TraceContext::TraceFlags->new(0);

            my $context = OpenTelemetry::Trace::SpanContext->new(
                trace_id    => $trace_id,
                span_id     => $span_id,
                trace_flags => $flags,
                trace_state => $result->trace_state,
            );

            $span{context}    = $context;
            $span{processors} = [ @processors ];

            return OpenTelemetry::SDK::Trace::Span->new(%span);
        }

        OpenTelemetry::Trace->non_recording_span(
            OpenTelemetry::Trace::SpanContext->new(
                trace_id    => $trace_id,
                span_id     => $span_id,
                trace_state => $result->trace_state,
            )
        );
    }

    method tracer (%args) {
        my %defaults;

        $defaults{scope} = do {
            # If no name is provided, we get it from the caller
            # This has to override the version, since the version
            # only makes sense for the name
            $args{name} || do {
                ( $args{name} ) = caller;
                $args{version}  = $args{name}->VERSION;
            };

            unless ( $args{name} ) {
                OpenTelemetry->logger->warn(
                    'Invalid name when retrieving tracer. Setting to empty string',
                    { value => $args{name} },
                );

                $args{name} //= '';
                delete $args{version};
            }

            OpenTelemetry::SDK::InstrumentationScope
                ->new( %args{qw( name version attributes )} );
        };

        $defaults{resource} = $args{schema_url}
            ? $resource->merge(
                OpenTelemetry::SDK::Resource->empty(
                    schema_url => $args{schema_url}
                ),
            )
            : $resource;

        $registry_lock->enter( sub {
            my $key
                = $defaults{scope}->to_string
                . '-'
                . $defaults{resource}->schema_url;

            $registry{$key} //= OpenTelemetry::SDK::Trace::Tracer->new(
                span_creator => sub { $self->$create_span( @_, %defaults ) },
            );
        });
    }

    method $atomic_call_on_processors ( $method, $timeout ) {
        my $start = timeout_timestamp;

        my $result = TRACE_EXPORT_SUCCESS;

        for my $processor ( @processors ) {
            my $remaining = maybe_timeout $timeout, $start;

            if ( $timeout && ! $remaining ) {
                $result = TRACE_EXPORT_TIMEOUT;
                last;
            }

            my $res = $processor->$method($remaining)->get;
            $result = $res if $res > $result;
        }


        return $result;
    }

    async method shutdown ( $timeout = undef ) {
        return TRACE_EXPORT_SUCCESS if $stopped;

        $lock->enter(
            sub {
                $stopped = 1;
                $self->$atomic_call_on_processors( shutdown => $timeout );
            }
        );
    }

    async method force_flush ( $timeout = undef ) {
        return TRACE_EXPORT_SUCCESS if $stopped;

        $lock->enter(
            sub {
                $self->$atomic_call_on_processors( force_flush => $timeout );
            }
        );
    }

    method add_span_processor ($processor) {
        $lock->enter( sub {
            return OpenTelemetry->logger
                ->warn('Attempted to add a span processor to a TraceProvider after shutdown')
                if $stopped;

            return OpenTelemetry->logger
                ->warn('Attempted to add an object that does not do the OpenTelemetry::Trace::Span::Processor role as a span processor to a TraceProvider')
                unless $processor->DOES('OpenTelemetry::Trace::Span::Processor');

            my $candidate = ref $processor;

            return OpenTelemetry->logger
                ->warn("Attempted to add a $candidate span processor to a TraceProvider more than once")
                if any { $_ isa $candidate } @processors;

            push @processors, $processor;
        });

        $self;
    }
}
