use Object::Pad ':experimental(init_expr)';
# ABSTRACT: A LoggerProvider for the OpenTelemetry SDK

package OpenTelemetry::SDK::Logs::LoggerProvider;

our $VERSION = '0.102';

class OpenTelemetry::SDK::Logs::LoggerProvider
    :isa(OpenTelemetry::Logs::LoggerProvider)
{
    use Future::AsyncAwait;
    use Mutex;
    use OpenTelemetry::Common qw( timeout_timestamp maybe_timeout );
    use OpenTelemetry::Constants -export;
    use OpenTelemetry::SDK::InstrumentationScope;
    use OpenTelemetry::SDK::Logs::Logger;
    use OpenTelemetry::SDK::Logs::LogRecord;
    use OpenTelemetry::SDK::Resource;
    use OpenTelemetry::Trace;
    use Time::HiRes 'time';

    field $resource :param //= OpenTelemetry::SDK::Resource->new;
    field $stopped = 0;
    field %registry;
    field @processors;

    field $lock          //= Mutex->new;
    field $registry_lock //= Mutex->new;

    my $logger = OpenTelemetry::Common::internal_logger;

    method $create_log_record (%args) {
        return if $stopped;

        my %log = %args{qw(
            attributes
            body
            observed_timestamp
            resource
            instrumentation_scope
            severity_number
            severity_text
            timestamp
            context
        )};

        $log{observed_timestamp} //= time;

        my $record = OpenTelemetry::SDK::Logs::LogRecord->new(%log);

        $_->on_emit($record) for @processors;

        $record;
    }

    method logger (%args) {
        my %defaults;

        $defaults{instrumentation_scope} = do {
            # If no name is provided, we get it from the caller
            # This has to override the version, since the version
            # only makes sense for the name
            $args{name} || do {
                ( $args{name} ) = caller;
                $args{version}  = $args{name}->VERSION;
            };

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
                = $defaults{instrumentation_scope}->to_string
                . '-'
                . $defaults{resource}->schema_url;

            $registry{$key} //= OpenTelemetry::SDK::Logs::Logger->new(
                callback => sub {
                    $self->$create_log_record( @_, %defaults );
                },
            );
        });
    }

    method $atomic_call_on_processors ( $method, $timeout ) {
        my $start = timeout_timestamp;

        my $result = EXPORT_RESULT_SUCCESS;

        for my $processor ( @processors ) {
            my $remaining = maybe_timeout $timeout, $start;

            if ( defined $remaining && $remaining == 0 ) {
                $result = EXPORT_RESULT_TIMEOUT;
                last;
            }

            my $res = $processor->$method($remaining)->get;
            $result = $res if $res > $result;
        }

        return $result;
    }

    async method shutdown ( $timeout = undef ) {
        return EXPORT_RESULT_SUCCESS if $stopped;

        $lock->enter(
            sub {
                $stopped = 1;
                $self->$atomic_call_on_processors( shutdown => $timeout );
            }
        );
    }

    async method force_flush ( $timeout = undef ) {
        return EXPORT_RESULT_SUCCESS if $stopped;

        $lock->enter(
            sub {
                $self->$atomic_call_on_processors( 'force_flush', $timeout );
            }
        );
    }

    method add_log_record_processor ($processor) {
        if ( $stopped ) {
            $logger->warn(
                'Attempted to add a log record processor to a LoggerProvider after shutdown'
            );
            return $self;
        }

        my $candidate = ref $processor;

        return $logger->warn("Attempted to add a $candidate object as a log record processor to a LoggerProvider, but it does not do the OpenTelemetry::Logs::LogRecord::Processor")
            unless $processor->DOES('OpenTelemetry::Logs::LogRecord::Processor');

        my %seen = map { ref, 1 } @processors;

        return $logger->warn("Attempted to add a $candidate log record processor to a LoggerProvider more than once")
            if $seen{$candidate};

        $lock->enter(
            sub { push @processors, $processor }
        );

        $self;
    }
}
