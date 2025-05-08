use Object::Pad ':experimental(init_expr)';

package OpenTelemetry::SDK::InstrumentationScope;

our $VERSION = '0.027';

class OpenTelemetry::SDK::InstrumentationScope :does(OpenTelemetry::Attributes) {
    use OpenTelemetry::Common;

    field $name    :param :reader;
    field $version :param :reader //= '';

    my $logger = OpenTelemetry::Common::internal_logger;

    ADJUST {
        $name ||= do {
            $logger->warn('Created an instrumentation scope with an undefined or empty name');
            '';
        };
    }

    method to_string () { '[' . $name . ':' . $version . ']' }
}
