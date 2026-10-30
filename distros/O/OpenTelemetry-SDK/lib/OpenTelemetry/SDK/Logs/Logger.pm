use Object::Pad;
# ABSTRACT: A Logger for the OpenTelemetry SDK

package OpenTelemetry::SDK::Logs::Logger;

our $VERSION = '0.101';

class OpenTelemetry::SDK::Logs::Logger :isa(OpenTelemetry::Logs::Logger) {
    field $callback :param;
    method emit_record ( %args ) {
        $callback->(%args);
    }
}
