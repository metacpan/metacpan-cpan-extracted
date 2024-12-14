use Object::Pad ':experimental(init_expr)';
# ABSTRACT: An OpenTelemetry Protocol span exporter

package OpenTelemetry::Exporter::OTLP;

our $VERSION = '0.019';

class OpenTelemetry::Exporter::OTLP :does(OpenTelemetry::Exporter) {
    use Feature::Compat::Try;
    use Future::AsyncAwait;
    use HTTP::Tiny;
    use Log::Any;
    use Module::Runtime 'require_module';
    use OpenTelemetry::Common qw( config maybe_timeout timeout_timestamp );
    use OpenTelemetry::Constants -trace_export;
    use OpenTelemetry::Context;
    use OpenTelemetry::Trace;
    use OpenTelemetry::X;
    use Syntax::Keyword::Dynamically;
    use Syntax::Keyword::Match;
    use Time::HiRes 'sleep';
    use Time::Piece;
    use URL::Encode 'url_decode';

    my $CAN_USE_PROTOBUF = eval {
        require Google::ProtocolBuffers::Dynamic;
        1;
    };

    my $PROTOCOL = $CAN_USE_PROTOBUF ? 'http/protobuf' : 'http/json';

    my $COMPRESSION = eval {
        require Compress::Zlib;
        'gzip';
    } // 'none';

    my $logger = Log::Any->get_logger( category => 'OpenTelemetry' );

    use Metrics::Any '$metrics', strict => 1,
        name_prefix => [qw( otel exporter otlp )];

    $metrics->make_counter( 'success',
        name        => [qw( success )],
        description => 'Number of times the export process succeeded',
    );

    $metrics->make_counter( 'failure',
        name        => [qw( failure )],
        description => 'Number of times the export process failed',
        labels      => [qw( reason )],
    );

    $metrics->make_distribution( 'uncompressed',
        name        => [qw( message uncompressed size )],
        description => 'Size of exporter payload before compression',
        units       => 'bytes',
    );

    $metrics->make_distribution( 'compressed',
        name        => [qw( message compressed size )],
        description => 'Size of exporter payload after compression',
        units       => 'bytes',
    );

    $metrics->make_timer( 'request',
        name        => [qw( request duration )],
        description => 'Duration of the export request',
        labels      => [qw( status )],
    );

    field $stopped;
    field $ua;
    field $endpoint;
    field $compression;
    field $encoder;
    field $retries;

    ADJUSTPARAMS ($params) {
        $endpoint = delete $params->{endpoint}
            // config('EXPORTER_OTLP_TRACES_ENDPOINT')
            // do {
                my $base = config('EXPORTER_OTLP_ENDPOINT')
                    // 'http://localhost:4318';

                ( $base =~ s|/+$||r ) . '/v1/traces';
            };

        $compression = delete $params->{compression}
            // config(<EXPORTER_OTLP_{TRACES_,}COMPRESSION>)
            // $COMPRESSION;

        $retries = delete $params->{retries} // 5;

        my $timeout = delete $params->{timeout}
            // config(<EXPORTER_OTLP_{TRACES_,}TIMEOUT>)
            // 10;

        my $headers = delete $params->{headers}
            // config(<EXPORTER_OTLP_{TRACES_,}HEADERS>)
            // {};

        $headers = {
            map {
                my ( $k, $v ) = map url_decode($_), split '=', $_, 2;
                $k =~ s/^\s+|\s+$//g;
                $v =~ s/^\s+|\s+$//g;
                $k => $v;
            } split ',', $headers
        } unless ref $headers;

        die OpenTelemetry::X->create(
            Invalid => "invalid URL for OTLP exporter: $endpoint"
        ) unless "$endpoint" =~ m|^https?://|;

        die OpenTelemetry::X->create(
            Unsupported => "unsupported compression key for OTLP exporter: $compression"
        ) unless $compression =~ /^(?:gzip|none)$/;

        $headers->{'Content-Encoding'} = $compression unless $compression eq 'none';

        $encoder = do {
            my $protocol = delete $params->{protocol}
                // config('EXPORTER_OTLP_PROTOCOL')
                // $PROTOCOL;

            die OpenTelemetry::X->create(
                Unsupported => "unsupported protocol for OTLP exporter: $protocol",
            ) unless $protocol =~ /^http\/(protobuf|json)$/;

            my $class = 'OpenTelemetry::Exporter::OTLP::Encoder::';
            $class .= 'Protobuf' if $1 eq 'protobuf';
            $class .= 'JSON'     if $1 eq 'json';

            try {
                require_module $class;
                $class->new;
            }
            catch ($e) {
                $logger->warn(
                    'Could not load OTLP encoder class. Defaulting to JSON',
                    { class => $class, error => $e },
                );

                require OpenTelemetry::Exporter::OTLP::Encoder::JSON;
                OpenTelemetry::Exporter::OTLP::Encoder::JSON->new;
            }
        };

        my %ssl_options;
        {
            my $ca = delete $params->{certificate} // config(qw(
                EXPORTER_OTLP_TRACES_CERTIFICATE
                EXPORTER_OTLP_CERTIFICATE
            ));

            my $key = delete $params->{client_key} // config(qw(
                EXPORTER_OTLP_TRACES_CLIENT_KEY
                EXPORTER_OTLP_CLIENT_KEY
            ));

            my $cert = delete $params->{client_certificate} // config(qw(
                EXPORTER_OTLP_TRACES_CLIENT_CERTIFICATE
                EXPORTER_OTLP_CLIENT_CERTIFICATE
            ));

            $ssl_options{SSL_ca_file}   = $ca   if $ca;
            $ssl_options{SSL_key_file}  = $key  if $key;
            $ssl_options{SSL_cert_file} = $cert if $cert;
        };

        $ua = HTTP::Tiny->new(
            timeout         => $timeout,
            agent           => "OTel-OTLP-Exporter-Perl/$VERSION",
            default_headers => {
                %$headers,
                'Content-Type' => $encoder->content_type,
            },
            %ssl_options ? ( SSL_options => \%ssl_options ) : (),
        );
    }

    method $maybe_backoff ( $attempts, $after = undef ) {
        $after //= 0; # Breaks tests in Perls under 5.38 if in signature

        return if $attempts > $retries;

        my $sleep;
        try {
            my $date = Time::Piece->strptime($after, '%a, %d %b %Y %T %Z');
            $sleep = ( $date - localtime )->seconds;
        }
        catch($e) {
            die $e unless $e =~ /^Error parsing time/;
            $sleep = $after if $after > 0;
        }
        $sleep //= int rand 2 ** $attempts;

        sleep $sleep + rand;

        return 1;
    }

    method $send_request ( $data, $timeout ) {
        my %request = ( content => $data );

        $metrics->report_distribution(
            uncompressed => length $request{content},
        );

        if ( $compression eq 'gzip' ) {
            require Compress::Zlib;
            $request{content} = Compress::Zlib::memGzip($request{content});

            unless ($request{content}) {
                OpenTelemetry->handle_error(
                    message => "Error compressing data: $Compress::Zlib::gzerrno"
                );

                $metrics->inc_counter(
                    failure => [ reason => 'zlib_error' ],
                );

                return TRACE_EXPORT_FAILURE;
            }

            $metrics->report_distribution(
                compressed => length $request{content},
            );
        }

        my $start    = timeout_timestamp;
        my $attempts = 0;
        while (1) {
            my $remaining = maybe_timeout $timeout, $start;
            return TRACE_EXPORT_TIMEOUT if $timeout && !$remaining;

            # We are changing the state of the user-agent here
            # There doesn't seem to be another way to do this.
            # As long as this exporter is running with the Batch
            # processor, it should only be processing one request
            # at a time, so this should not be a problem.
            $ua->timeout($remaining);

            my $request_start = timeout_timestamp;
            my $res = $ua->post( $endpoint, \%request );
            my $request_end = timeout_timestamp;

            $metrics->report_timer(
                request => $request_end - $request_start,
                [ status => $res->{status} ],
            );

            if ( $res->{success} ) {
                $metrics->inc_counter('success');
                return TRACE_EXPORT_SUCCESS;
            }

            match ( $res->{status} : =~ ) {
                case( m/^ 599 $/x ) {
                    my $reason = do {
                        match ( $res->{content} : =~ ) {
                            case(m/^Timed out/)                { 'timeout' }
                            case(m/^Could not connect /)       { 'socket_error' }
                            case(m/^Could not .* socket /)     { 'socket_error' }
                            case(m/^Socket closed /)           { 'socket_error' }
                            case(m/^Wide character in write/)  { 'socket_error' }
                            case(m/^Error halting .* SSL /)    { 'ssl_error' }
                            case(m/^SSL connection failed /)   { 'ssl_error' }
                            case(m/^Unexpected end of stream/) { 'eof_error' }
                            case(m/^Cannot parse/)             { 'parse_error' }
                            default {
                                $metrics->inc_counter(
                                    failure => [ reason => $res->{status} ],
                                );

                                OpenTelemetry->handle_error(
                                    exception => $res->{content},
                                    message   => 'Unhandled error sending OTLP request',
                                );

                                return TRACE_EXPORT_FAILURE;
                            }
                        }
                    };

                    $metrics->inc_counter( failure => [ reason => $reason ] );

                    redo if $self->$maybe_backoff( ++$attempts );
                }
                case( m/^(?: 4 | 5 ) \d{2} $/ax ) {
                    my $code = $res->{status};

                    $metrics->inc_counter( failure => [ reason => $code ] );

                    if ( $CAN_USE_PROTOBUF ) {
                        try {
                            require OpenTelemetry::Proto;

                            my $status = OTel::Google::RPC::Status
                                ->decode($res->{content});

                            OpenTelemetry->handle_error(
                                exception => $status->encode_json,
                                message   => 'OTLP exporter received an RPC error status',
                            );
                        }
                        catch($e) {
                            OpenTelemetry->handle_error(
                                exception => $e,
                                message   => 'Unexpected error decoding RPC status in OTLP exporter',
                            );
                        }
                    }

                    my $after = ( $code == 429 || $code == 503 )
                        ? $res->{headers}{'retry-after'}
                        : undef;

                    # As-per https://opentelemetry.io/docs/specs/otlp/#failures-1
                    redo if (  $code == 429
                            || $code == 502
                            || $code == 503
                            || $code == 504
                        ) && $self->$maybe_backoff( ++$attempts, $after );
                }
            }

            return TRACE_EXPORT_FAILURE;
        }
    }

    method export ( $data, $timeout = undef ) {
        return TRACE_EXPORT_FAILURE if $stopped;
        return unless @$data;

        try {
            dynamically OpenTelemetry::Context->current
                = OpenTelemetry::Trace->untraced_context;

            my $request = $encoder->encode($data);
            my $result  = $self->$send_request( $request, $timeout );

            $metrics->inc_counter('success');

            return $result;
        }
        catch($e) {
            warn "Could not export data: $e";
            return TRACE_EXPORT_FAILURE;
        }
    }

    async method shutdown ( $timeout = undef ) {
        $stopped = 1;
        TRACE_EXPORT_SUCCESS;
    }

    async method force_flush ( $timeout = undef ) {
        TRACE_EXPORT_SUCCESS;
    }
}
