use Object::Pad ':experimental(init_expr)';
# ABSTRACT: Represents an OpenTelemetry log entry

package OpenTelemetry::SDK::Logs::LogRecord;

our $VERSION = '0.102';

class OpenTelemetry::SDK::Logs::LogRecord {
    use Ref::Util 'is_ref';
    use Storable 'dclone';
    use Time::HiRes 'time';
    use OpenTelemetry::Trace;

    field $attributes            :param //= {};
    field $timestamp             :param :reader = undef;
    field $observed_timestamp    :param :reader //= time;
    field $context               :param = undef;
    field $severity_text         :param :reader;
    field $severity_number       :param :reader;
    field $resource              :param :reader;
    field $instrumentation_scope :param :reader;
    field $body                  :param;

    ADJUSTPARAMS ($params) {
        $attributes = dclone $attributes;
        $body = is_ref $body ? dclone $body : $body;

        # The constructor accepts an OpenTelemetry::Context
        # but we only store the SpanContext internally
        $context = OpenTelemetry::Trace
            ->span_from_context($context)->context;
    }

    method body { is_ref $body ? dclone $body : $body }

    # TODO: We don't currently restrict LogRecord attributes
    # The spec is a little vague on exactly how the attribute
    # restrictions work for LogRecord objects, but a reasonable
    # interpretation would be that the normal restrictions apply
    # _except_ the one that states that values can be either
    # nuclear types, or arrays of nuclear types. The ability
    # to set attributes that are nested arbitrarily deep is
    # needed to support existing loggers in the wild, and this
    # is not currently supported by OpenTelemetry::Attributes.
    # If we want to add it we'd probably need some way to
    # opt-in to the lax behaviour, probably like we used to do
    # for read-write attributes, which was removed in
    # 66ff6a4d83afdeb99882e524f7e37261fe337304.
    # Alternatively, we can expose the attribute validation
    # logic so we can call it from here, but that'd be more
    # awkward, because it relies on knowing what the limits
    # are. Let's not even get into the name of the SpanLimits
    # class, which would now apply to more than just spans...
    method dropped_attributes () { 0 }
    method attributes { dclone $attributes }

    method     trace_flags () { $context->trace_flags  }
    method     trace_state () { $context->trace_state  }
    method     trace_id    () { $context->trace_id     }
    method hex_trace_id    () { $context->hex_trace_id }
    method     span_id     () { $context->span_id      }
    method hex_span_id     () { $context->hex_span_id  }
}
