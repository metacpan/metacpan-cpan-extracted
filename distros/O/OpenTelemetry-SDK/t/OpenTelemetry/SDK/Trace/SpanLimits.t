#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::SDK::Trace::SpanLimits';
use Test2::Tools::Spec;
use Test2::Tools::OpenTelemetry;

subtest Defaults => sub {
    is CLASS->new, object {
        call attribute_count_limit        => 128;
        call event_attribute_count_limit  => 128;
        call link_attribute_count_limit   => 128;

        call attribute_length_limit       => U;
        call event_attribute_length_limit => U;

        call event_count_limit            => 128;
        call link_count_limit             => 128;
    };
};

describe 'Validation' => sub {
    describe 'Values without defaults' => sub {
        my %env;

        case 'General attribute length' => sub {
            %env = (
                OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT => 0,
            );
        };

        case 'Specific attribute length' => sub {
            %env = (
                OTEL_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT  => 0,
                OTEL_EVENT_ATTRIBUTE_VALUE_LENGTH_LIMIT => 0,
                OTEL_LINK_ATTRIBUTE_VALUE_LENGTH_LIMIT  => 0,
            );
        };

        case 'Not numeric values' => sub {
            %env = (
                OTEL_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT  => 'foo',
                OTEL_EVENT_ATTRIBUTE_VALUE_LENGTH_LIMIT => {},
                OTEL_LINK_ATTRIBUTE_VALUE_LENGTH_LIMIT  => 'garbage',
            );
        };

        it 'Works' => sub {
            local %ENV = %env;
            is messages {
                is CLASS->new, object {
                    call attribute_length_limit       => U;
                    call event_attribute_length_limit => U;
                }, 'Ignored invalid values';
            } => [
                [ warning => OpenTelemetry => match qr/attribute_length_limit .* greater than 32 if set/ ],
                [ warning => OpenTelemetry => match qr/event_attribute_length_limit .* greater than 32 if set/ ],
                [ warning => OpenTelemetry => match qr/link_attribute_length_limit.* greater than 32 if set/ ],
            ], 'Logged invalid values';
        };
    };

    subtest 'General attribute count' => sub {
        local %ENV = (
            OTEL_ATTRIBUTE_COUNT_LIMIT => -1,
        );

        is messages {
            is CLASS->new, object {
                call attribute_count_limit        => 128;
                call event_attribute_count_limit  => 128;
                call link_attribute_count_limit   => 128;
                call event_count_limit            => 128;
                call link_count_limit             => 128;
            };
        } => [
            [ warning => OpenTelemetry => match qr/event_attribute_count_limit .* positive integer/ ],
            [ warning => OpenTelemetry => match qr/link_attribute_count_limit .* positive integer/ ],
            [ warning => OpenTelemetry => match qr/attribute_count_limit .* positive integer/ ],
        ], 'Logged invalid values';
    };

    describe 'Values with defaults' => sub {
        my %env;

        case 'Specific attribute count' => sub {
            %env = (
                OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT  => -10,
                OTEL_EVENT_ATTRIBUTE_COUNT_LIMIT => -11,
                OTEL_LINK_ATTRIBUTE_COUNT_LIMIT  => -12,
                OTEL_SPAN_EVENT_COUNT_LIMIT      => -13,
                OTEL_SPAN_LINK_COUNT_LIMIT       => -14,
            );
        };

        case 'Not numeric values' => sub {
            %env = (
                OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT  => 'fox',
                OTEL_EVENT_ATTRIBUTE_COUNT_LIMIT => 'fxo',
                OTEL_LINK_ATTRIBUTE_COUNT_LIMIT  => 'xfo',
                OTEL_SPAN_EVENT_COUNT_LIMIT      => 'xof',
                OTEL_SPAN_LINK_COUNT_LIMIT       => 'ofx',
            );
        };

        case 'Not integer values' => sub {
            %env = (
                OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT  => 1.1,
                OTEL_EVENT_ATTRIBUTE_COUNT_LIMIT => 1.2,
                OTEL_LINK_ATTRIBUTE_COUNT_LIMIT  => 1.3,
                OTEL_SPAN_EVENT_COUNT_LIMIT      => 1.4,
                OTEL_SPAN_LINK_COUNT_LIMIT       => 1.5,
            );
        };

        it 'Works' => sub {
            local %ENV = %env;
            is messages {
                is CLASS->new, object {
                    call attribute_count_limit        => 128;
                    call event_attribute_count_limit  => 128;
                    call link_attribute_count_limit   => 128;
                    call event_count_limit            => 128;
                    call link_count_limit             => 128;
                }, 'Ignored invalid values';
            } => [
                [ warning => OpenTelemetry => match qr/event_attribute_count_limit .* positive integer/ ],
                [ warning => OpenTelemetry => match qr/link_attribute_count_limit .* positive integer/ ],
                [ warning => OpenTelemetry => match qr/attribute_count_limit .* positive integer/ ],
                [ warning => OpenTelemetry => match qr/event_count_limit .* positive integer/ ],
                [ warning => OpenTelemetry => match qr/link_count_limit .* positive integer/ ],
            ], 'Logged invalid values';
        };
    };
};

subtest 'OTEL variables' => sub {
    local %ENV = (
        OTEL_ATTRIBUTE_COUNT_LIMIT        => 99,
        OTEL_ATTRIBUTE_VALUE_LENGTH_LIMIT => 999,
    );

    is CLASS->new, object {
        call attribute_count_limit        => 99;
        call event_attribute_count_limit  => 99;
        call link_attribute_count_limit   => 99;

        call attribute_length_limit       => 999;
        call event_attribute_length_limit => 999;

        call event_count_limit            => 128;
        call link_count_limit             => 128;
    };

    subtest 'Specific variables' => sub {
        local %ENV = (
            %ENV,
            OTEL_SPAN_ATTRIBUTE_COUNT_LIMIT         => 100,
            OTEL_EVENT_ATTRIBUTE_COUNT_LIMIT        => 101,
            OTEL_LINK_ATTRIBUTE_COUNT_LIMIT         => 102,

            OTEL_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT  => 103,
            OTEL_EVENT_ATTRIBUTE_VALUE_LENGTH_LIMIT => 104,
            OTEL_LINK_ATTRIBUTE_VALUE_LENGTH_LIMIT  => 105,

            OTEL_SPAN_EVENT_COUNT_LIMIT             => 106,
            OTEL_SPAN_LINK_COUNT_LIMIT              => 107,
        );

        is CLASS->new, object {
            call attribute_count_limit        => 100;
            call event_attribute_count_limit  => 101;
            call link_attribute_count_limit   => 102;

            call attribute_length_limit       => 103;
            call event_attribute_length_limit => 104;
            call link_attribute_length_limit  => 105;

            call event_count_limit            => 106;
            call link_count_limit             => 107;
        };
    };

    subtest 'PERL variables' => sub {
        local %ENV = (
            %ENV,
            OTEL_PERL_SPAN_ATTRIBUTE_COUNT_LIMIT         => 200,
            OTEL_PERL_EVENT_ATTRIBUTE_COUNT_LIMIT        => 201,
            OTEL_PERL_LINK_ATTRIBUTE_COUNT_LIMIT         => 202,

            OTEL_PERL_SPAN_ATTRIBUTE_VALUE_LENGTH_LIMIT  => 203,
            OTEL_PERL_EVENT_ATTRIBUTE_VALUE_LENGTH_LIMIT => 204,
            OTEL_PERL_LINK_ATTRIBUTE_VALUE_LENGTH_LIMIT  => 205,

            OTEL_PERL_SPAN_EVENT_COUNT_LIMIT             => 206,
            OTEL_PERL_SPAN_LINK_COUNT_LIMIT              => 207,
        );

        is CLASS->new, object {
            call attribute_count_limit        => 200;
            call event_attribute_count_limit  => 201;
            call link_attribute_count_limit   => 202;

            call attribute_length_limit       => 203;
            call event_attribute_length_limit => 204;
            call link_attribute_length_limit  => 205;

            call event_count_limit            => 206;
            call link_count_limit             => 207;
        };
    };
};

done_testing;
