#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::SDK::Trace::TracerProvider';
use Test2::Tools::OpenTelemetry;

subtest Tracer => sub {
    my $provider = CLASS->new;

    no_messages {
        is my $default = $provider->tracer, object {
            prop isa => 'OpenTelemetry::SDK::Trace::Tracer';
        }, 'Can get tracer with no arguments';

        is my $specific = $provider->tracer( name => 'foo', version => 123 ),
            object { prop isa => 'OpenTelemetry::SDK::Trace::Tracer';
        }, 'Can get tracer with name and version';

        ref_is $provider->tracer( name => 'foo', version => 123 ), $specific,
            'Equivalent request returns cached tracer provider';
    };
};

subtest SpanProcessors => sub {
    my $provider = CLASS->new;
    my $processor = mock {} => add => [ DOES => 1 ];

    no_messages {
        ref_is $provider->add_span_processor($processor), $provider,
            'Adding span processor chains';
    };

    is messages {
        ref_is $provider->add_span_processor($processor), $provider,
            'Adding span processor chains';
    } => [
        [
            warning => 'OpenTelemetry',
            match qr/^Attempted to add .* span processor .* more than once/,
        ],
    ] => 'Warned about repeated processor';
};

done_testing;
