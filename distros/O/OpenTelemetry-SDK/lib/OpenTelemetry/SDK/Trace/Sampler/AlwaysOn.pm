use Object::Pad ':experimental(init_expr)';
# ABSTRACT: An sampler with that will always sample

package OpenTelemetry::SDK::Trace::Sampler::AlwaysOn;

our $VERSION = '0.025';

use OpenTelemetry::SDK::Trace::Sampler::Result;

class OpenTelemetry::SDK::Trace::Sampler::AlwaysOn
    :does(OpenTelemetry::SDK::Trace::Sampler)
{
    use OpenTelemetry::Trace;

    method description () { 'AlwaysOnSampler' }

    method should_sample (%args) {
        OpenTelemetry::SDK::Trace::Sampler::Result->new(
            decision => OpenTelemetry::SDK::Trace::Sampler::Result::RECORD_AND_SAMPLE,
            trace_state => OpenTelemetry::Trace
                ->span_from_context($args{context})->context->trace_state,
        )
    }
}
