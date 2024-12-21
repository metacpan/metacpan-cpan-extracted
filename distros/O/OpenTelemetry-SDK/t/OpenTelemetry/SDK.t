#!/usr/bin/env perl

use Test2::V0;
use Test2::Tools::Spec;
use Test2::Tools::OpenTelemetry;

use Object::Pad ':experimental(mop)';
use Sentinel;
use OpenTelemetry;
use OpenTelemetry::SDK::Trace::TracerProvider; # For mocking
use Module::Runtime;

require OpenTelemetry::SDK;

my $tracer_provider_mock = mock 'OpenTelemetry::SDK::Trace::TracerProvider';
my         $require_mock = mock 'Module::Runtime';

my ( $propagator, $tracer_provider );
my $mock = mock OpenTelemetry => override => [
    propagator => sub :lvalue {
        sentinel
            get => sub { $propagator },
            set => sub { $propagator = shift };
    },
    tracer_provider => sub :lvalue {
        sentinel
            get => sub { $tracer_provider },
            set => sub { $tracer_provider = shift };
    },
];

after_each Clear => sub { $propagator = $tracer_provider = undef };

it 'Can be disabled' => sub {
    local %ENV = ( OTEL_SDK_DISABLED => 1 );
    OpenTelemetry::SDK->import;
    is $tracer_provider, U, 'Leaves tracer provider unchanged';
};

it 'Dies on broken modules' => sub {
    local %ENV = (
        OTEL_TRACES_EXPORTER => 'console',
        OTEL_PROPAGATORS     => 'baggage',
    );

    my $orig = \&Module::Runtime::require_module;
    $require_mock->override(
        require_module => sub ($) {
            goto $orig
                if $_[0] !~ /^OpenTelemetry/
                || $_[0] =~ /^OpenTelemetry::X/;
            die 'oops';
        },
    );

    like dies { OpenTelemetry::SDK->import },
        qr/^Error configuring 'baggage' propagator: oops/;

    $require_mock->reset_all;
};

it 'Dies on errors during import' => sub {
    my $orig = \&OpenTelemetry::SDK::config;
    my $die = mock 'OpenTelemetry::SDK' => override => [
        config => sub {
            goto $orig if $_[0] eq 'SDK_DISABLED';
            die 'boom';
        },
    ];

    like dies { OpenTelemetry::SDK->import },
        qr/^Unexpected error initialising OpenTelemetry::SDK: boom/;
};

describe 'Propagators' => sub {
    describe 'Valid input' => sub {
        my ( $env, @keys );

        case None => sub {
            $env  = 'none';
            @keys = ();
        };

        case Baggage => sub {
            $env  = 'baggage';
            @keys = qw( baggage );
        };

        case TraceContext => sub {
            $env  = 'tracecontext';
            @keys = qw( traceparent tracestate );
        };

        case Default => sub {
            $env  = '';
            @keys = qw( traceparent tracestate baggage );
        };

        it 'Works' => sub {
            local %ENV = (
                OTEL_TRACES_EXPORTER => 'console',
                OTEL_PROPAGATORS     => $env,
            );

            no_messages { OpenTelemetry::SDK->import };

            is $propagator, object {
                prop isa => 'OpenTelemetry::Propagator::Composite';
                call_list keys => \@keys;
            }, 'Installed correct propagator';
        };
    };

    tests 'Unknown propagator' => sub {
        local %ENV = (
            OTEL_TRACES_EXPORTER => 'console',
            OTEL_PROPAGATORS     => 'foo',
        );

        is messages { OpenTelemetry::SDK->import }, [
            [ warning => OpenTelemetry => match qr/Unknown propagator 'foo'/ ],
        ], 'Logged unknown propagator';

        is $propagator, object {
            prop isa => 'OpenTelemetry::Propagator::Composite';
            call_list keys => [];
        }, 'Ignored unknown propagator';
    };
};

describe 'Span processors' => sub {
    my ( $env, $processor, $exporter, @keys );

    before_all Mock => sub {
        $tracer_provider_mock->override(
            new => sub {
                mock {} => track => 1;
            },
        );
    };

    after_all 'Clear mock' => sub {
        $tracer_provider_mock->reset_all;
    };

    describe Valid => sub {

        case Console => sub {
            $env       = 'console';
            $exporter  = 'OpenTelemetry::SDK::Exporter::Console';
            $processor = 'OpenTelemetry::SDK::Trace::Span::Processor::Simple';
        };

        it 'Works' => sub {
            local %ENV = ( OTEL_TRACES_EXPORTER => $env );

            no_messages { OpenTelemetry::SDK->import };

            my ($tracker) = mocked $tracer_provider;
            is $tracker->call_tracking, [
                {
                    sub_name => 'add_span_processor',
                    sub_ref  => D,
                    args     => [
                        D,
                        object {
                            prop isa  => $processor;
                            call sub {
                                Object::Pad::MOP::Class->for_class($processor)
                                    ->get_field('$exporter')
                                    ->value(shift);
                            } => object {
                                prop isa => $exporter;
                            }
                        }
                    ],
                }
            ], 'Installed correct exporter and processor';
        };
    };

    tests None => sub {
        local %ENV = ( OTEL_TRACES_EXPORTER => 'none' );

        no_messages { OpenTelemetry::SDK->import };

        my ($tracker) = mocked $tracer_provider;
        is $tracker->call_tracking, [], 'Ignored processor';
    };

    tests Unknown => sub {
        local %ENV = ( OTEL_TRACES_EXPORTER => 'foo' );

        is messages { OpenTelemetry::SDK->import }, [
            [ warning => OpenTelemetry => match qr/Unknown exporter 'foo'/ ],
        ], 'Logged unknown exporter';

        my ($tracker) = mocked $tracer_provider;
        is $tracker->call_tracking, [], 'Ignored processor';
    };
};

done_testing;
