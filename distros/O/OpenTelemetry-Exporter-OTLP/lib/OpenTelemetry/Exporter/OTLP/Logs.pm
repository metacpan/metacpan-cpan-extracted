use Object::Pad ':experimental(init_expr)';
# ABSTRACT: An OpenTelemetry Protocol log exporter

package OpenTelemetry::Exporter::OTLP::Logs;

our $VERSION = '0.019';

class OpenTelemetry::Exporter::OTLP::Logs :isa(OpenTelemetry::Exporter::OTLP) {
    use OpenTelemetry::Common 'config';

    my $COMPRESSION = eval { require Compress::Zlib; 'gzip' } // 'none';

    sub BUILDARGS ( $class, %args ) {
        $args{endpoint}
            //= config('EXPORTER_OTLP_LOGS_ENDPOINT')
            // do {
                my $base = config('EXPORTER_OTLP_ENDPOINT')
                    // 'http://localhost:4318';

                ( $base =~ s|/+$||r ) . '/v1/logs';
            };

        # We cannot rely on the defaults on the base OTLP exporter
        # because at least for now, that one defaults to the TRACES
        # variables. Once it doesn't, we can simplify this to match
        # the code in the Traces exporter
        $args{compression}
            //= config(<EXPORTER_OTLP_{LOGS_,}COMPRESSION>)
            // $COMPRESSION;

        $args{timeout} //= config(<EXPORTER_OTLP_{LOGS_,}TIMEOUT>) // 10;
        $args{headers} //= config(<EXPORTER_OTLP_{LOGS_,}HEADERS>) // {};

        %args;
    }
}
