use Object::Pad ':experimental(init_expr)';

package OpenTelemetry::SDK::InstrumentationScope;

our $VERSION = '0.024';

class OpenTelemetry::SDK::InstrumentationScope :does(OpenTelemetry::Attributes) {
    use OpenTelemetry;

    field $name    :param :reader;
    field $version :param :reader //= '';

    ADJUST {
        $name ||= do {
            OpenTelemetry->logger
                ->warn('Created an instrumentation scope with an undefined or empty name');
            '';
        };
    }

    method to_string () { '[' . $name . ':' . $version . ']' }
}
