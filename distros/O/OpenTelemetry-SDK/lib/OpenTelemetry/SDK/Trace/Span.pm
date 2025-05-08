use Object::Pad ':experimental( init_expr mop )';

package OpenTelemetry::SDK::Trace::Span;

our $VERSION = '0.027';

use OpenTelemetry::Attributes;

class OpenTelemetry::SDK::Trace::Span
    :isa(OpenTelemetry::Trace::Span)
    :does(OpenTelemetry::Attributes)
{
    use List::Util qw( any pairs );
    use Ref::Util qw( is_arrayref is_hashref );
    use Time::HiRes 'time';

    use OpenTelemetry::Constants
        -span_kind => { -as => sub { shift =~ s/^SPAN_KIND_//r } };

    use OpenTelemetry::Common ();
    use OpenTelemetry::SDK::Trace::SpanLimits;
    use OpenTelemetry::SDK::Trace::Span::Readable;
    use OpenTelemetry::Trace::Event;
    use OpenTelemetry::Trace::Link;
    use OpenTelemetry::Trace::SpanContext;
    use OpenTelemetry::Trace::Span::Status;
    use OpenTelemetry::Trace;

    use isa qw(
        Exception::Base
        Exception::Class::Base
        OpenTelemetry::Trace::SpanContext
    );

    my $logger = OpenTelemetry::Common::internal_logger;

    field $dropped_events      = 0;
    field $dropped_links       = 0;
    field $end;
    field $kind       :param   = INTERNAL;
    field $limits     :param //= OpenTelemetry::SDK::Trace::SpanLimits->new;
    field $name       :param;
    field $resource   :param   = undef;
    field $scope      :param;
    field $start      :param   = undef;
    field $status              = OpenTelemetry::Trace::Span::Status->unset;
    field @events;
    field @links;
    field @processors;
    field $parent_span_context;

    # Internal method for adding a single link
    #
    #     $self->$add_link({
    #         context    => $valid_span_context,
    #         attributes => \%link_attributes,
    #     })
    #
    # Links with invalid span contexts are ignored
    #
    method $add_link ( $args ) {
        return unless isa_OpenTelemetry_Trace_SpanContext($args->{context})
            && $args->{context}->valid;

        if ( scalar @links >= $limits->link_count_limit ) {
            $dropped_links++;
            $logger->warn('Dropped link because it would exceed specified limit');
            return;
        }

        push @links, OpenTelemetry::Trace::Link->new(
            context                => $args->{context},
            attributes             => $args->{attributes},
            attribute_count_limit  => $limits->link_attribute_count_limit,
        );
    }

    ADJUSTPARAMS ( $params ) {
        my $now = time;
        undef $start if $start && $start > $now;
        $start //= $now;

        $kind = INTERNAL if $kind < INTERNAL || $kind > CONSUMER;

        @processors = @{ delete $params->{processors} // [] };

        $self->$add_link($_) for @{ delete $params->{links} // [] };

        my $parent = delete $params->{parent};

        $parent_span_context
            = OpenTelemetry::Trace->span_from_context($parent)->context;

        $_->on_start( $self, $parent ) for @processors;
    }

    method set_name ( $new ) {
        return $self unless $self->recording && $new;

        $name = $new;

        $self;
    }

    method set_attribute ( %new ) {
        unless ( $self->recording ) {
            $logger->warn('Attempted to set attributes on a span that is not recording');
            return $self
        }

        # FIXME: Ideally an overridable method from role, but that is not supported
        Object::Pad::MOP::Class->for_class('OpenTelemetry::Attributes')
            ->get_field('$attributes')
            ->value($self)
            ->set(%new);

        $self;
    }

    method set_status ( $new, $description = undef ) {
        return $self if !$self->recording || $status->is_ok;

        my $value = OpenTelemetry::Trace::Span::Status->new(
            code        => $new,
            description => $description // '',
        );

        $status = $value unless $value->is_unset;

        $self;
    }

    method add_event (%args) {
        return $self unless $self->recording;

        if ( scalar @events >= $limits->event_count_limit ) {
            $dropped_events++;
            $logger->warn('Dropped event because it would exceed specified limit');
            return $self;
        }

        push @events, OpenTelemetry::Trace::Event->new(
            name                   => $args{name},
            timestamp              => $args{timestamp},
            attributes             => $args{attributes},
            attribute_count_limit  => $limits->event_attribute_count_limit,
            attribute_length_limit => $limits->event_attribute_length_limit,
        );

        $self;
    }

    method end ( $time = undef ) {
        # This should in theory be an atomic check. For now, to reduce
        # the chances of it becoming a problem, we check the field
        # directly instead of going through `recording`
        return $self if defined $end;
        $end = $time // time;

        $_->on_end($self) for @processors;

        $self;
    }

    method record_exception ( $exception, %attributes ) {
        return $self unless $self->recording;

        my ( $message, $stacktrace );
        if ( isa_Exception_Class_Base $exception ) {
            $message    = $exception->message;
            $stacktrace = $exception->trace->as_string;
        }
        else {
            # This should cover the following common exceptions:
            # * Catalyst::Exception::Basic
            # * Class::Throwable
            # * Dancer::Exception::Base
            # * Exception::Base
            # * Mojo::Exception
            # * Throwable::Error
            # * X::Tiny
            # * plain die strings

            local $ENV{MOJO_EXCEPTION_VERBOSE} = 1;
            local $Class::Throwable::DEFAULT_VERBOSITY = 2;

            ( $message, $stacktrace ) = split /\n/, "$exception", 2;

            $stacktrace //= $exception->get_caller_stacktrace
                if isa_Exception_Base $exception;
        }

        $self->add_event(
            name       => 'exception',
            attributes => {
                'exception.type'       => ref $exception || 'string',
                'exception.message'    => $message,
                'exception.stacktrace' => $stacktrace,
                %attributes,
            }
        );
    }

    method recording () { ! defined $end }

    method snapshot () {
        OpenTelemetry::SDK::Trace::Span::Readable->new(
            attributes            => $self->attributes,
            context               => $self->context,
            dropped_events        => $dropped_events,
            dropped_links         => $dropped_links,
            end_timestamp         => $end,
            events                => [ @events ],
            instrumentation_scope => $scope,
            kind                  => $kind,
            links                 => [ @links ],
            name                  => $name,
            parent_span_id        => $parent_span_context->span_id,
            resource              => $resource,
            start_timestamp       => $start,
            status                => $status,
        );
    }
}
