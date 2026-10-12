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
my $logger_provider_mock = mock 'OpenTelemetry::SDK::Logs::LoggerProvider';
my         $require_mock = mock 'Module::Runtime';

my $propagator      = my $original_propagator      = OpenTelemetry->propagator;
my $tracer_provider = my $original_tracer_provider = OpenTelemetry->tracer_provider;
my $logger_provider = my $original_logger_provider = OpenTelemetry->logger_provider;

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
    logger_provider => sub :lvalue {
        sentinel
            get => sub { $logger_provider },
            set => sub { $logger_provider = shift };
    },
];

after_each Clear => sub {
    $propagator      = $original_propagator;
    $tracer_provider = $original_tracer_provider;
    $logger_provider = $original_logger_provider;
};

describe Import => sub {
    it 'Can be disabled' => sub {
        local %ENV = ( OTEL_SDK_DISABLED => 1 );
        OpenTelemetry::SDK->import;
        ref_is $tracer_provider, $original_tracer_provider,
            'Leaves tracer provider unchanged';
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
};

describe Propagators => sub {
    describe Environment => sub {
        describe Valid => sub {
            my ( $class, @keys );

            case None => sub {
                $class = 'None';
                @keys  = ();
            };

            case Baggage => sub {
                $class = 'Baggage';
                @keys  = qw( baggage );
            };

            case TraceContext => sub {
                $class = 'TraceContext';
                @keys  = qw( traceparent tracestate );
            };

            case Default => sub {
                $class = '';
                @keys  = qw( traceparent tracestate baggage );
            };

            it 'Works' => { flat => 1 } => sub {
                local %ENV = (
                    OTEL_TRACES_EXPORTER => 'console',
                    OTEL_PROPAGATORS     => lc $class,
                );

                no_messages { OpenTelemetry::SDK->configure_propagators };

                $class ||= 'Composite';
                is $propagator, object {
                    prop isa => 'OpenTelemetry::Propagator::' . $class;
                    call_list keys => \@keys;
                }, 'Installed correct propagator';
            };
        };

        tests Invalid => sub {
            local %ENV = (
                OTEL_TRACES_EXPORTER => 'console',
                OTEL_PROPAGATORS     => 'foo',
            );

            is messages { OpenTelemetry::SDK->configure_propagators } => [
                [ warning => OpenTelemetry => match qr/Unknown propagator 'foo'/ ],
            ], 'Logged unknown propagator';

            ref_is $propagator, $original_propagator,
                'Ignored unknown propagator';
        };
    };

    describe Programmatic => sub {
        class Local::Propagator::Good :isa(OpenTelemetry::Propagator::None) {}
        class Local::Propagator::Bad {}

        describe Valid => sub {
            my (@args, $check);

            case Blessed => sub {
                @args  = Local::Propagator::Good->new;
                $check = 'Local::Propagator::Good';
            };

            case Named => sub {
                @args  = 'baggage';
                $check = 'OpenTelemetry::Propagator::Baggage';
            };

            case Mixed => sub {
                @args  = ( 'tracecontext', undef, Local::Propagator::Good->new );
                $check = 'OpenTelemetry::Propagator::Composite';
            };

            it 'Works' => { flat => 1 } => sub {
                local %ENV = ( OTEL_PROPAGATORS => 'none' );

                no_messages {
                    my $propagator = OpenTelemetry::SDK
                        ->configure_propagators(@args);

                    is $propagator, object {
                        prop isa => $check;
                    }, 'Installed correct propagator';
                };
            };
        };

        describe Invalid => sub {
            my (@args, $check);

            case Blessed => sub {
                @args  = Local::Propagator::Bad->new;
                $check = match qr/^Attempted to configure a 'Local::Propagator::Bad'/;
            };

            case Named => sub {
                @args  = 'baggggage';
                $check = match qr/^Unknown propagator 'baggggage'/;
            };

            it 'Works' => { flat => 1 } => sub {
                local %ENV = ( OTEL_PROPAGATORS => 'none' );

                is messages {
                    my $propagator = OpenTelemetry::SDK
                        ->configure_propagators(@args);

                    ref_is $propagator, $original_propagator,
                        'Propagator is untouched';
                } => [
                    [ warning => OpenTelemetry => $check ],
                ];
            };
        };
    };
};

describe TracerProvider => sub {
    describe Environment => sub {
        before_all Mock => sub {
            $tracer_provider_mock->override(
                new => sub { mock {} => track => 1 },
            );
        };

        after_all 'Clear mock' => sub {
            $tracer_provider_mock->reset_all;
        };

        my ( $env, $calls, $messages );

        case Console => sub {
            $env   = 'console';
            $messages = [];
            $calls = [
                {
                    sub_name => 'add_span_processor',
                    sub_ref  => D,
                    args     => [
                        D,
                        object {
                            prop isa  => 'OpenTelemetry::SDK::Trace::Span::Processor::Simple';
                            call sub {
                                my ($meta) = Object::Pad::MOP::Class->for_class( ref $_[0] )->superclasses;
                                $meta->get_field('$exporter')->value($_[0]);
                            } => object {
                                prop isa => 'OpenTelemetry::SDK::Exporter::Console';
                            };
                        },
                    ],
                },
            ];
        };

        case None => sub {
            $env = 'none';
            $calls = $messages = [];
        };

        case Unknown => sub {
            $env = 'foo';
            $messages = [
                [ warning => OpenTelemetry => match qr/Unknown exporter 'foo'/ ],
            ];
            $calls = [];
        };

        it 'Works' => { flat => 1 } => sub {
            local %ENV = ( OTEL_TRACES_EXPORTER => $env );

            is messages {
                OpenTelemetry::SDK->configure_tracer_provider;
            } => $messages, 'Logged expected messages';

            my ($tracker) = mocked $tracer_provider;
            is $tracker->call_tracking, $calls,
                'Installed correct exporter and processor';
        };
    };

    describe Programmatic => sub {
        local %ENV = ( OTEL_TRACES_EXPORTER => 'none' );

        my ( @args, $messages, $return, $calls );

        tests 'Bad provider' => sub {
            is messages {
                my $provider = OpenTelemetry::SDK
                    ->configure_tracer_provider(mock);

                is $provider => object {
                    prop isa => 'OpenTelemetry::SDK::Trace::TracerProvider';
                } => 'Returns expected provider';
            } => [
                [
                    'warning',
                    'OpenTelemetry',
                    match qr/Attempted to configure .* but it does not implement/,
                ],
            ];
        };

        tests 'Unblessed provider' => sub {
            is messages {
                my $provider = OpenTelemetry::SDK
                    ->configure_tracer_provider('oops');

                is $provider => object {
                    prop isa => 'OpenTelemetry::SDK::Trace::TracerProvider';
                } => 'Returns expected provider';
            } => [
                [
                    'warning',
                    'OpenTelemetry',
                    match qr/was not a blessed reference: oops/,
                ],
            ];
        };

        tests 'Good provider' => sub {
            class Local::Trace::Provider::Good {
                field @calls :reader;
                method tracer             { push @calls, 'tracer' }
                method force_flush        { push @calls, 'force_flush' }
                method shutdown           { push @calls, 'shutdown' }
                method add_span_processor { push @calls, 'add_span_processor' }
            }

            no_messages {
                my $provider = OpenTelemetry::SDK
                    ->configure_tracer_provider(Local::Trace::Provider::Good->new);
                is $provider => object {
                    prop isa => 'Local::Trace::Provider::Good';
                } => 'Returns expected provider';

                is [ $provider->calls ], ['add_span_processor'],
                    'Configured provider';
           }, 'Logged expected messages';
       };
    };
};

describe LoggerProvider => sub {
    describe Environment => sub {
        before_all Mock => sub {
            $logger_provider_mock->override(
                new => sub { mock {} => track => 1 },
            );
        };

        after_all 'Clear mock' => sub {
            $logger_provider_mock->reset_all;
        };

        my ( $env, $calls, $messages );

        case Console => sub {
            $env   = 'console';
            $messages = [];
            $calls = [
                {
                    sub_name => 'add_log_record_processor',
                    sub_ref  => D,
                    args     => [
                        D,
                        object {
                            prop isa  => 'OpenTelemetry::SDK::Logs::LogRecord::Processor::Simple';
                            call sub {
                                my ($meta) = Object::Pad::MOP::Class->for_class( ref $_[0] )->superclasses;
                                $meta->get_field('$exporter')->value($_[0]);
                            } => object {
                                prop isa => 'OpenTelemetry::SDK::Exporter::Console';
                            };
                        },
                    ],
                },
            ];
        };

        case None => sub {
            $env = 'none';
            $calls = $messages = [];
        };

        case Unknown => sub {
            $env = 'foo';
            $messages = [
                [ warning => OpenTelemetry => match qr/Unknown exporter 'foo'/ ],
            ];
            $calls = [];
        };

        it 'Works' => { flat => 1 } => sub {
            local %ENV = ( OTEL_LOGS_EXPORTER => $env );

            is messages {
                OpenTelemetry::SDK->configure_logger_provider;
            } => $messages, 'Logged expected messages';

            my ($tracker) = mocked $logger_provider;
            is $tracker->call_tracking, $calls,
                'Installed correct exporter and processor';
        };
    };

    describe Programmatic => sub {
        local %ENV = ( OTEL_LOGS_EXPORTER => 'none' );

        my ( @args, $messages, $return, $calls );

        tests 'Bad provider' => sub {
            is messages {
                my $provider = OpenTelemetry::SDK
                    ->configure_logger_provider(mock);

                is $provider => object {
                    prop isa => 'OpenTelemetry::SDK::Logs::LoggerProvider';
                } => 'Returns expected provider';
            } => [
                [
                    'warning',
                    'OpenTelemetry',
                    match qr/Attempted to configure .* but it does not implement/,
                ],
            ];
        };

        tests 'Unblessed provider' => sub {
            is messages {
                my $provider = OpenTelemetry::SDK
                    ->configure_logger_provider('oops');

                is $provider => object {
                    prop isa => 'OpenTelemetry::SDK::Logs::LoggerProvider';
                } => 'Returns expected provider';
            } => [
                [
                    'warning',
                    'OpenTelemetry',
                    match qr/was not a blessed reference: oops/,
                ],
            ];
        };

        tests 'Good provider' => sub {
            class Local::Log::Provider::Good {
                field @calls :reader;
                method logger                   { push @calls, 'logger' }
                method force_flush              { push @calls, 'force_flush' }
                method shutdown                 { push @calls, 'shutdown' }
                method add_log_record_processor { push @calls, 'add_log_record_processor' }
            }

            no_messages {
                my $provider = OpenTelemetry::SDK
                    ->configure_logger_provider(Local::Log::Provider::Good->new);
                is $provider => object {
                    prop isa => 'Local::Log::Provider::Good';
                } => 'Returns expected provider';

                is [ $provider->calls ], ['add_log_record_processor'],
                    'Configured provider';
           }, 'Logged expected messages';
       };
    };
};

done_testing;
