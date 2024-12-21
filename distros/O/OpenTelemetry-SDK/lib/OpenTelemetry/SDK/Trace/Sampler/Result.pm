use Object::Pad ':experimental(init_expr)';
# ABSTRACT: The result of a sampling decision

package OpenTelemetry::SDK::Trace::Sampler::Result;

our $VERSION = '0.025';

use constant {
    DROP              => 0,
    RECORD_ONLY       => 1,
    RECORD_AND_SAMPLE => 2,
};

class OpenTelemetry::SDK::Trace::Sampler::Result :does(OpenTelemetry::Attributes) {
    field $trace_state :param :reader;
    field $decision    :param;

    ADJUST {
        no warnings qw( uninitialized numeric );
        $decision = DROP
            unless $decision >= RECORD_ONLY
                && $decision <= RECORD_AND_SAMPLE;
    }

    method sampled () { $decision eq RECORD_AND_SAMPLE }

    method recording () { $decision ne DROP }
}
