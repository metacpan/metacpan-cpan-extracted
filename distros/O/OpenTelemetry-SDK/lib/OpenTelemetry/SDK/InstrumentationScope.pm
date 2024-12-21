use Object::Pad ':experimental(init_expr)';

package OpenTelemetry::SDK::InstrumentationScope;

our $VERSION = '0.025';

class OpenTelemetry::SDK::InstrumentationScope :does(OpenTelemetry::Attributes) {
    use Log::Any;

    field $name    :param :reader;
    field $version :param :reader //= '';

    my $logger = Log::Any->get_logger( category => 'OpenTelemetry' );

    ADJUST {
        $name ||= do {
            $logger->warn('Created an instrumentation scope with an undefined or empty name');
            '';
        };
    }

    method to_string () { '[' . $name . ':' . $version . ']' }
}
