use Object::Pad ':experimental( init_expr mop )';
# ABSTRACT: A class that governs the configuration of spans

package OpenTelemetry::SDK::Trace::SpanLimits;

our $VERSION = '0.026';

class OpenTelemetry::SDK::Trace::SpanLimits {
    use List::Util 'first';
    use Log::Any;
    use OpenTelemetry::Common 'config';
    use Ref::Util 'is_arrayref';
    use Scalar::Util 'looks_like_number';

    my $logger = Log::Any->get_logger( category => 'OpenTelemetry');

    field        $attribute_count_limit :reader = config(qw(  SPAN_ATTRIBUTE_COUNT_LIMIT ATTRIBUTE_COUNT_LIMIT )) // 128;
    field  $event_attribute_count_limit :reader = config(qw( EVENT_ATTRIBUTE_COUNT_LIMIT ATTRIBUTE_COUNT_LIMIT )) // 128;
    field   $link_attribute_count_limit :reader = config(qw(  LINK_ATTRIBUTE_COUNT_LIMIT ATTRIBUTE_COUNT_LIMIT )) // 128;

    field       $attribute_length_limit :reader = config(qw(  SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT ATTRIBUTE_VALUE_LENGTH_LIMIT ));
    field $event_attribute_length_limit :reader = config(qw( EVENT_ATTRIBUTE_VALUE_LENGTH_LIMIT ATTRIBUTE_VALUE_LENGTH_LIMIT ));
    field  $link_attribute_length_limit :reader = config(qw(  LINK_ATTRIBUTE_VALUE_LENGTH_LIMIT ATTRIBUTE_VALUE_LENGTH_LIMIT ));

    field            $event_count_limit :reader = config(qw( SPAN_EVENT_COUNT_LIMIT )) // 128;
    field             $link_count_limit :reader = config(qw(  SPAN_LINK_COUNT_LIMIT )) // 128;

    ADJUST {
        my $meta   = Object::Pad::MOP::Class->for_caller;

        my $optional_number_with_min = sub ( $name, $min ) {
            my $field = $meta->get_field( '$' . $name );
            my $value = $field->value($self);

            return unless defined $value;
            return if looks_like_number $value && int $value == $value && $value >= $min;

            $logger->warn(
                "Invalid value for SpanLimits: $name must be an integer greater than $min if set",
                { value => $value },
            );

            $field->value($self) = undef;
        };

        my $must_be_positive_int = sub ( $name, $default ) {
            my $field = $meta->get_field( '$' . $name );
            my $value = $field->value($self);

            return if looks_like_number $value && int $value == $value && $value > 0;

            $logger->warn(
                "Invalid value for SpanLimits: $name must be a positive integer",
                { value => $value },
            );

            $field->value($self) = $default;
        };

        $optional_number_with_min->(       attribute_length_limit => 32 );
        $optional_number_with_min->( event_attribute_length_limit => 32 );
        $optional_number_with_min->(  link_attribute_length_limit => 32 );

        $must_be_positive_int->( event_attribute_count_limit => 128 );
        $must_be_positive_int->(  link_attribute_count_limit => 128 );
        $must_be_positive_int->(       attribute_count_limit => 128 );
        $must_be_positive_int->(           event_count_limit => 128 );
        $must_be_positive_int->(            link_count_limit => 128 );
    }
}
