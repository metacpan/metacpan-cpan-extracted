#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::SDK::Trace::Span';
use Test2::Tools::OpenTelemetry;

use OpenTelemetry::Constants -span_status, -span_kind, 'INVALID_SPAN_ID';
use OpenTelemetry::Trace;
use OpenTelemetry::SDK::InstrumentationScope;
use OpenTelemetry::X;

my $scope = OpenTelemetry::SDK::InstrumentationScope->new( name => 'test' );

subtest 'Set name' => sub {
    is my $span = CLASS->new( name => 'foo', scope => $scope ), object {
        prop isa       => 'OpenTelemetry::SDK::Trace::Span';
        call recording => T;
        call sub { shift->snapshot->name } => 'foo';
    }, 'Created a recording span with specified name';

    is $span->set_name('bar'), object {
        call sub { shift->snapshot->name } => 'bar';
    }, 'Set new name and chained';

    is $span->set_name(''), object {
        call sub { shift->snapshot->name } => 'bar';
    }, 'Cannot set empty string as name';

    is $span->set_name(undef), object {
        call sub { shift->snapshot->name } => 'bar';
    }, 'Cannot set undef as name';

    is $span->end->set_name('baz'), object {
        call sub { shift->snapshot->name } => 'bar';
    }, 'Does not modify name if span is ended';
};

subtest 'Set attributes' => sub {
    is my $span = CLASS->new(
        name       => 'foo',
        scope      => $scope,
        attributes => { foo => 123 },
    ) => object {
        prop isa       => 'OpenTelemetry::SDK::Trace::Span';
        call recording => T;
        call sub { shift->snapshot->attributes } => { foo => 123 };
    }, 'Created a recording span with specified attributes';

    is $span->set_attribute( foo => 234 ), object {
        call sub { shift->snapshot->attributes } => { foo => 234 };
    }, 'Set new attributes and chained';

    is messages {
        is $span->end->set_attribute( foo => 345 ), object {
            call sub { shift->snapshot->attributes } => { foo => 234 };
        }, 'Does not modify attributes if span is ended';
    } => [
        [ warning => OpenTelemetry => match q/set attributes .* not recording/ ],
    ], 'Trying to set attribute on ended span fails and logs';
};

subtest 'Events' => sub {
    local $ENV{OTEL_SPAN_EVENT_COUNT_LIMIT} = 3;

    is my $span = CLASS->new( name => 'foo', scope  => $scope ) => object {
        prop isa       => 'OpenTelemetry::SDK::Trace::Span';
        call recording => T;
        call_list sub { shift->snapshot->events } => [];
    }, 'Created a recording span with no events';

    is messages {
        is $span
            ->add_event( name => 'default' )
            ->add_event(
                name       => 'attributes',
                attributes => { foo => 123 },
            )
            ->add_event(
                name       => 'timestamp',
                timestamp  => 1234567890.123,
            )
            ->add_event( name => 'over limit' )
            ->end
            ->add_event( name => 'after end' )
            ->snapshot, object {
                call_list events => [
                    object {
                        call name       => 'default';
                        call timestamp  => D;
                        call attributes => {},
                    },
                    object {
                        call name       => 'attributes';
                        call timestamp  => D;
                        call attributes => { foo => 123 },
                    },
                    object {
                        call name       => 'timestamp';
                        call timestamp  => 1234567890.123;
                        call attributes => {},
                    },
                ];
            }, 'Added events to span but only if recording';
    } => [
        [ warning => OpenTelemetry => match qr/^Dropped event/ ],
    ], 'Logged attempt to add event after end';

    is CLASS->new( name => 'foo', scope  => $scope )
        ->record_exception( "Died\nFrom somewhere" ) => object {
            call_list sub { shift->snapshot->events } => [
                object {
                    call name       => 'exception';
                    call attributes => {
                        'exception.type'       => 'string',
                        'exception.message'    => 'Died',
                        'exception.stacktrace' => 'From somewhere',
                    };
                },
            ];
        }, 'Recorded exception';

    is CLASS->new( name => 'foo', scope  => $scope )
        ->record_exception( "Died\nFrom somewhere", foo => 123 ) => object {
            call_list sub { shift->snapshot->events } => [
                object {
                    call name       => 'exception';
                    call attributes => {
                        'exception.type'       => 'string',
                        'exception.message'    => 'Died',
                        'exception.stacktrace' => 'From somewhere',
                        'foo'                  => 123,
                    };
                },
            ];
        }, 'Recorded exception with attributes';

    is CLASS->new( name => 'foo', scope  => $scope )->record_exception(
        OpenTelemetry::X->create( Invalid => 'Died' )
    ) => object {
            call_list sub { shift->snapshot->events } => [
                object {
                    call name       => 'exception';
                    call attributes => {
                        'exception.type'       => 'OpenTelemetry::X::Invalid',
                        'exception.message'    => 'Died',
                        'exception.stacktrace' => match qr/called in \S+ at line /,
                    };
                },
            ];
        }, 'Recorded blessed exception';
};

subtest End => sub {
    is CLASS->new( name => 'foo', scope => $scope )->end => object {
        call recording => F;
    }, 'Ended span is not recording';

    is CLASS->new( name => 'foo', scope => $scope )->end(123) => object {
        call sub { shift->snapshot->end_timestamp } => 123;
    }, 'Ended span with timestamp';

    no_messages {
        is CLASS->new( name => 'foo', scope => $scope )->end(1)->end(2), object {
            call sub { shift->snapshot->end_timestamp } => 1;
        }, 'Second end is ignored';
    };
};

subtest 'Set status' => sub {
    is my $span = CLASS->new( name => 'foo', scope => $scope ) => object {
        prop isa       => 'OpenTelemetry::SDK::Trace::Span';
        call recording => T;
        call sub { shift->snapshot->status->code } => SPAN_STATUS_UNSET;
    }, 'Created a recording span with specified status';

    is $span->set_status( SPAN_STATUS_ERROR ), object {
        call sub { shift->snapshot->status } => object {
            call code        => SPAN_STATUS_ERROR;
            call description => '';
        };
    }, 'Set new status and chained';

    is $span->set_status( SPAN_STATUS_ERROR, 'foo'), object {
        call sub { shift->snapshot->status } => object {
            call code        => SPAN_STATUS_ERROR;
            call description => 'foo';
        };
    }, 'Can set description with error status';

    is $span->set_status( SPAN_STATUS_UNSET ), object {
        call sub { shift->snapshot->status } => object {
            call code        => SPAN_STATUS_ERROR;
            call description => 'foo';
        };
    }, 'Cannot unset a set status';

    is $span->set_status( SPAN_STATUS_OK ), object {
        call sub { shift->snapshot->status } => object {
            call code        => SPAN_STATUS_OK;
            call description => '';
        };
    }, 'Can set status to OK';

    is $span->set_status( SPAN_STATUS_ERROR ), object {
        call sub { shift->snapshot->status } => object {
            call code        => SPAN_STATUS_OK;
            call description => '';
        };
    }, 'Cannot change status from OK';

    is my $ended = CLASS->new( name => 'foo', scope => $scope )->end, object {
        call recording => F;
    }, 'Created a non-recording span';

    is $ended->set_status( SPAN_STATUS_OK ) => object {
        call sub { shift->snapshot->status->code } => SPAN_STATUS_UNSET;
    }, 'Cannot change status of ended span';
};

is CLASS->new( name => 'foo', scope => $scope ), object {
    call snapshot => object {
        prop isa => 'OpenTelemetry::SDK::Trace::Span::Readable';
        call attributes            => {};
        call end_timestamp         => U;
        call_list events           => [];
        call instrumentation_scope => object { call to_string => '[test:]' };
        call kind                  => SPAN_KIND_INTERNAL;
        call_list links            => [];
        call name                  => 'foo';
        call parent_span_id        => INVALID_SPAN_ID;
        call resource              => U;
        call span_id               => validator(sub { length == 8 });
        call start_timestamp       => T;
        call dropped_attributes    => 0;
        call dropped_events        => 0;
        call dropped_links         => 0;
        call trace_flags           => object { call flags => 0 };
        call trace_id              => validator(sub { length == 16 });
        call trace_state           => object { call to_string => '' };
        call status => object {
           call code        => SPAN_STATUS_UNSET;
           call description => '';
        };
    };
}, 'Can create readable snapshot';

done_testing;
