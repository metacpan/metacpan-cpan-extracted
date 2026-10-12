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

    no_messages {
        is my $tracer = $provider->tracer( name => undef, version => 123 ),
            object { prop isa => 'OpenTelemetry::SDK::Trace::Tracer';
        }, 'Got tracer even with bad name';

        is $tracer->create_span( name => 'foo' ), object {
            call snapshot => object {
                call instrumentation_scope => object {
                    call to_string => '[main:]';
                };
            };
        }, 'Scope name defaults to caller and version is dropped';
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

subtest Shutdown => sub {
    my $provider = CLASS->new;
    my $processor = mock {} => track => 1 => add => [
        DOES        => 1,
        shutdown    => sub { Future->done(0) },
    ];

    my ($mocked) = mocked $processor;

    $provider->add_span_processor($processor);

    is $provider->shutdown(123)->get, 0, 'Returned success';

    is $provider->shutdown->get, 0, 'Returned success';

    like $mocked->call_tracking => [
        { sub_name => 'DOES',     args => [ D, T   ] },
        { sub_name => 'shutdown', args => [ D, rounded( 123, 0 ) ] },
    ], 'Forwarded to processor but only once';

    is messages {
        $provider
            ->add_span_processor( mock {} => add => [ DOES => 1 ] );
    } => [
        [
            warning => 'OpenTelemetry',
            match qr/^Attempted to add a span processor .* after shutdown/,
        ],
    ];
};

subtest Flushing => sub {
    my $provider = CLASS->new;
    my $processor = mock {} => track => 1 => add => [
        DOES        => 1,
        force_flush => sub { Future->done(0) },
    ];

    my ($mocked) = mocked $processor;

    $provider->add_span_processor($processor);

    is $provider->force_flush(123)->get, 0, 'Returned success';

    is $provider->force_flush->get, 0, 'Returned success';

    like $mocked->call_tracking => [
        { sub_name => 'DOES',        args => [ D, T   ] },
        { sub_name => 'force_flush', args => [ D, rounded( 123, 0 ) ] },
    ], 'Forwarded to processor but only once';
};

done_testing;
