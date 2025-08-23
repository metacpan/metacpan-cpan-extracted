use Object::Pad ':experimental(init_expr)';
# ABSTRACT: A composite sampler

package OpenTelemetry::SDK::Trace::Sampler::ParentBased;

our $VERSION = '0.028';

class OpenTelemetry::SDK::Trace::Sampler::ParentBased
    :does(OpenTelemetry::SDK::Trace::Sampler)
{
    use OpenTelemetry::Trace;
    use OpenTelemetry::SDK::Trace::Sampler::AlwaysOff;
    use OpenTelemetry::SDK::Trace::Sampler::AlwaysOn;

    field $root                      :param;
    field $remote_parent_sampled     :param //= OpenTelemetry::SDK::Trace::Sampler::AlwaysOn->new;
    field $remote_parent_not_sampled :param //= OpenTelemetry::SDK::Trace::Sampler::AlwaysOff->new;
    field $local_parent_sampled      :param //= OpenTelemetry::SDK::Trace::Sampler::AlwaysOn->new;
    field $local_parent_not_sampled  :param //= OpenTelemetry::SDK::Trace::Sampler::AlwaysOff->new;

    method description () {
        sprintf 'ParentBased{root=%s,remote_parent_sampled=%s,remote_parent_not_sampled=%s,local_parent_sampled=%s,local_parent_not_sampled=%s}',
            map $_->description,
                $root,
                $remote_parent_sampled,
                $remote_parent_not_sampled,
                $local_parent_sampled,
                $local_parent_not_sampled;
    }

    method should_sample (%args) {
        my $span_context = OpenTelemetry::Trace
            ->span_from_context($args{context})->context;

        my $sampled = $span_context->trace_flags->sampled;

        my $delegate = !$span_context->valid
            ? $root
            : $span_context->remote
                ? $sampled
                    ? $remote_parent_sampled
                    : $remote_parent_not_sampled
                : $sampled
                    ? $local_parent_sampled
                    : $local_parent_not_sampled;

        $delegate->should_sample(%args);
    }
}
