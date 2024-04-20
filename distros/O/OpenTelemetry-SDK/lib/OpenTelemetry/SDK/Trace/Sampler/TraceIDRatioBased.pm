use Object::Pad ':experimental(init_expr)';
# ABSTRACT: A sampler based on the trace ID

package OpenTelemetry::SDK::Trace::Sampler::TraceIDRatioBased;

our $VERSION = '0.022';

use OpenTelemetry::SDK::Trace::Sampler::Result;

class OpenTelemetry::SDK::Trace::Sampler::TraceIDRatioBased
    :does(OpenTelemetry::SDK::Trace::Sampler)
{
    use OpenTelemetry;
    use Scalar::Util 'looks_like_number';

    field $threshold;
    field $ratio       :param = 1;
    field $description :reader;

    ADJUST {
        my $logger = OpenTelemetry->logger;

        unless ( looks_like_number $ratio ) {
            $logger->warn(
                'Ratio for TraceIDRatioBased sampler was not a number',
                { ratio => $ratio },
            );
            undef $ratio;
        }

        if ( defined $ratio && ( $ratio < 0 || $ratio > 1 ) ) {
            $logger->warn(
                'Ratio for TraceIDRatioBased sampler was not in 0..1 range',
                { ratio => $ratio },
            );
            undef $ratio;
        }

        $ratio //= 1;

        # Ensure ratio is a floating point number
        # but don't lose precision
        $description = sprintf 'TraceIDRatioBased{%s}',
            $ratio != int $ratio
                ? sprintf('%f',   $ratio) =~ s/0+$//r
                : sprintf('%.1f', $ratio);

        # This conversion is internal only, just for the placeholder
        # algorithm used below. We convert this to an integer value that
        # can be compared directly with the one derived from the Trace ID,
        # in the range from 0 (never sample) to 2**64 (always sample)
        $threshold = do {
            use bignum;
            # Since Math::BigFloat 1.999840 onwards, the shift operators are
            # exclusively integer-based, so we enforce precedent here
            ( $ratio * ( 1 << 64 ) )->bceil;
        };
    }

    method should_sample (%args) {
        my $trace_state = OpenTelemetry::Trace
            ->span_from_context($args{context})
            ->context->trace_state;

        # TODO: The specific algorithm of this sampler is still being
        # determined. See: https://github.com/open-telemetry/opentelemetry-specification/issues/1413
        # The algorithm implemented below is equivalent to the version
        # used by the Ruby and Go SDKs at the time of writing.

        if ($ratio) {
            my $check = do {
                # We don't care about uninitialised values, since those
                # will just turn into zeroes, which is safe.
                no warnings 'uninitialized';

                # We drop the first 8 bytes and parse the last 8 as an
                # unsigned 64-bit big-endian integer.
                # The dance with N2 instead of Q> is because Q> requires
                # 64-bit integer support on both this specific version of
                # perl (lowercase) and the system that runs it.
                my ( $hi, $lo ) = unpack 'x8 N2', $args{trace_id};
                $hi << 32 | $lo;
            };

            return OpenTelemetry::SDK::Trace::Sampler::Result->new(
                decision    => OpenTelemetry::SDK::Trace::Sampler::Result::RECORD_AND_SAMPLE,
                trace_state => $trace_state,
            ) if $check < $threshold;
        }

        return OpenTelemetry::SDK::Trace::Sampler::Result->new(
            decision    => OpenTelemetry::SDK::Trace::Sampler::Result::DROP,
            trace_state => $trace_state,
        );
    }
}
