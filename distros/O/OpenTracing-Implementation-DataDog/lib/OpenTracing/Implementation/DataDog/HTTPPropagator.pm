package OpenTracing::Implementation::DataDog::HTTPPropagator;

use strict;
use warnings;
use Moo;
use MooX::Attribute::ENV;
use Carp qw[ croak ];

use constant {
    STYLE_DATADOG   => 'datadog',
    STYLE_B3_SINGLE => 'b3 single header',
    STYLE_B3_MULTI  => 'b3multi',
    STYLE_W3C       => 'tracecontext',
    STYLE_NONE      => 'none',
};

my %styles = (
    STYLE_DATADOG    ,=> 'OpenTracing::Implementation::DataDog::Propagator::DataDog',
    STYLE_B3_SINGLE  ,=> 'OpenTracing::Implementation::DataDog::Propagator::B3Single',
    STYLE_B3_MULTI   ,=> 'OpenTracing::Implementation::DataDog::Propagator::B3Multi',
    STYLE_W3C        ,=> 'OpenTracing::Implementation::DataDog::Propagator::TraceState',
    STYLE_NONE       ,=> 'OpenTracing::Implementation::DataDog::Propagator::NoOp',
);

has _style_extract => (
    is      => 'ro',
    default => STYLE_DATADOG,
    env_key => [
        'DD_TRACE_PROPAGATION_STYLE_EXTRACT',
        'DD_TRACE_PROPAGATION_STYLE',
    ],
);

has _style_inject => (
    is      => 'ro',
    default => STYLE_DATADOG,
    env_key => [
        'DD_TRACE_PROPAGATION_STYLE_INJECT',
        'DD_TRACE_PROPAGATION_STYLE',
    ],
);

has extractor => (
    is      => 'lazy',
    handles => [qw/extract/],
    default => sub {
        my ($self) = @_;
        $self->make_propagator($self->_style_extract);
    },
);

has injector => (
    is      => 'lazy',
    handles => [qw/inject/],
    default => sub {
        my ($self) = @_;
        $self->make_propagator($self->_style_inject);
    },
);

sub make_propagator {
    my ($self, $style) = @_;
    my @propagators = map { $_->new } map {
        s/\A\s*|\s*\z//g;
        $styles{$_} // croak "Unsupported propagation style: $_"
    } split ',', $style;
    return $propagators[0] if @propagators == 1;
    return OpenTracing::Implementation::DataDog::Propagator::Multi->new(@propagators);
}

package OpenTracing::Implementation::DataDog::Propagator::DataDog {
    use Moo;

    use constant {
        HTTP_HEADER_TRACE_ID => "x-datadog-trace-id",
        HTTP_HEADER_SPAN_ID  => "x-datadog-parent-id",
    };

    sub inject {
        my ($self, $carrier, $context) = @_;
        $carrier->header(HTTP_HEADER_TRACE_ID, $context->trace_id);
        $carrier->header(HTTP_HEADER_SPAN_ID, $context->span_id);
        return;
    }

    sub extract {
        my ($self, $carrier) = @_;
        return (
            $carrier->header(HTTP_HEADER_TRACE_ID),
            $carrier->header(HTTP_HEADER_SPAN_ID),
        );
    }
}

package OpenTracing::Implementation::DataDog::Propagator::B3Single {
    use Moo;

    use constant HTTP_HEADER_B3_SINGLE => "b3";

    sub inject {
        my ($self, $carrier, $context) = @_;
        $carrier->header(HTTP_HEADER_B3_SINGLE,
            join '-', $context->trace_id, $context->span_id);
        return;
    }

    sub extract {
        my ($self, $carrier) = @_;
        return split '-', $carrier->header(HTTP_HEADER_B3_SINGLE);
    }
}

package OpenTracing::Implementation::DataDog::Propagator::B3Multi {
    use Moo;

    use constant {
        HTTP_HEADER_B3_TRACE_ID => "x-b3-traceid",
        HTTP_HEADER_B3_SPAN_ID  => "x-b3-spanid",
    };

    sub inject {
        my ($self, $carrier, $context) = @_;
        $carrier->header(HTTP_HEADER_B3_TRACE_ID, $context->trace_id);
        $carrier->header(HTTP_HEADER_B3_SPAN_ID, $context->span_id);
        return;
    }

    sub extract {
        my ($self, $carrier) = @_;
        return (
            $carrier->header(HTTP_HEADER_B3_TRACE_ID),
            $carrier->header(HTTP_HEADER_B3_SPAN_ID),
        );
    }
}

package OpenTracing::Implementation::DataDog::Propagator::TraceState {
    use Moo;

    use constant HTTP_HEADER_TRACEPARENT => "traceparent";

    sub inject {
        my ($self, $carrier, $context) = @_;

        # version and sampling priority not supported at the moment
        my $traceparent = sprintf '00-%032x-%016x-00',
            $context->trace_id, $context->span_id;
        $carrier->header(HTTP_HEADER_TRACEPARENT, $traceparent);

        return;
    }

    sub extract {
        my ($self, $carrier) = @_;

        no warnings 'portable'; # ids could greater than 0xffffffff

        my (undef, $trace_id, $span_id, undef) 
            = split '-', $carrier->header(HTTP_HEADER_TRACEPARENT);
        return map { hex } $trace_id, $span_id;
    }
}

package OpenTracing::Implementation::DataDog::Propagator::Multi {
    use Moo;

    has propagators => (
        is      => 'ro',
        default => sub { [] },
    );

    around BUILDARGS => sub {
        my ($orig, $class, @args) = @_;
        return $class->$orig({ propagators => \@args });
    };

    sub inject {
        my ($self, $carrier, $context) = @_;
        $_->inject($carrier, $context) foreach @{ $self->propagators };
        return;
    }

    sub extract {
        my ($self, $carrier) = @_;
        foreach my $extractor (@{ $self->propagators }) {
            my ($trace_id, $span_id) = $extractor->extract($carrier);
            return ($trace_id, $span_id) if defined $trace_id and defined $span_id;
        }
        return;
    }
}

package OpenTracing::Implementation::DataDog::Propagator::NoOp {
    use Moo;

    sub inject  { }
    sub extract { undef, undef }
}

1;
