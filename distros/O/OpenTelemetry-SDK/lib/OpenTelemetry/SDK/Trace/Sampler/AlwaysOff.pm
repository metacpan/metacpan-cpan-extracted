use Object::Pad ':experimental(init_expr)';
# ABSTRACT: An sampler with that will never sample

package OpenTelemetry::SDK::Trace::Sampler::AlwaysOff;

our $VERSION = '0.022';

use OpenTelemetry::SDK::Trace::Sampler::Result;

class OpenTelemetry::SDK::Trace::Sampler::AlwaysOff
    :does(OpenTelemetry::SDK::Trace::Sampler)
{
    use OpenTelemetry::Trace;

    method description () { 'AlwaysOffSampler' }

    method should_sample (%args) {
        OpenTelemetry::SDK::Trace::Sampler::Result->new(
            decision => OpenTelemetry::SDK::Trace::Sampler::Result::DROP,
            trace_state => OpenTelemetry::Trace
                ->span_from_context($args{context})->context->trace_state,
        )
    }
}
