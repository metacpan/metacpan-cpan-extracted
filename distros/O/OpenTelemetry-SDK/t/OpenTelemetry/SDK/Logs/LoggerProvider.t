#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::SDK::Logs::LoggerProvider';
use Test2::Tools::OpenTelemetry;

subtest Logger => sub {
    my $provider = CLASS->new;

    no_messages {
        is my $default = $provider->logger, object {
            prop isa => 'OpenTelemetry::SDK::Logs::Logger';
        }, 'Can get logger with no arguments';

        is my $specific = $provider->logger( name => 'foo', version => 123 ),
            object { prop isa => 'OpenTelemetry::SDK::Logs::Logger';
        }, 'Can get logger with name and version';

        ref_is $provider->logger( name => 'foo', version => 123 ), $specific,
            'Equivalent request returns cached tracer provider';

        is $specific->emit_record( body => 'foo' ), object {
            call observed_timestamp    => T;
            call body                  => 'foo';
            call instrumentation_scope => object {
                call to_string => '[foo:123]';
            };
        }, 'Generates expected record';
    };

    no_messages {
        is my $logger = $provider->logger( name => undef, version => 123 ),
            object { prop isa => 'OpenTelemetry::SDK::Logs::Logger';
        }, 'Got logger even with bad name';

        is $logger->emit_record( body => 'foo' ), object {
            call instrumentation_scope => object {
                call to_string => '[main:]';
            };
        }, 'Scope name defaults to caller and version is dropped';
    };
};

subtest LogRecordProcessors => sub {
    my $provider = CLASS->new;
    my $processor = mock {} => add => [ DOES => 1 ];

    no_messages {
        ref_is $provider->add_log_record_processor($processor), $provider,
            'Adding log record processor chains';
    };

    is messages {
        $provider->add_log_record_processor(mock);
    } => [
        [
            warning => 'OpenTelemetry',
            match qr/^Attempted to add .* log record processor .* does not do/,
        ],
    ] => 'Warned about non-compliant processor';

    is messages {
        $provider->add_log_record_processor($processor), $provider;
    } => [
        [
            warning => 'OpenTelemetry',
            match qr/^Attempted to add .* log record processor .* more than once/,
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

    $provider->add_log_record_processor($processor);

    is $provider->shutdown(123)->get, 0, 'Returned success';

    is $provider->shutdown->get, 0, 'Returned success';

    like $mocked->call_tracking => [
        { sub_name => 'DOES',     args => [ D, T   ] },
        { sub_name => 'shutdown', args => [ D, rounded( 123, 0 ) ] },
    ], 'Forwarded to processor but only once';

    is messages {
        $provider
            ->add_log_record_processor( mock {} => add => [ DOES => 1 ] );
    } => [
        [
            warning => 'OpenTelemetry',
            match qr/^Attempted to add a log record processor .* after shutdown/,
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

    $provider->add_log_record_processor($processor);

    is $provider->force_flush(123)->get, 0, 'Returned success';

    is $provider->force_flush->get, 0, 'Returned success';

    like $mocked->call_tracking => [
        { sub_name => 'DOES',        args => [ D, T   ] },
        { sub_name => 'force_flush', args => [ D, rounded( 123, 0 ) ] },
    ], 'Forwarded to processor but only once';
};

done_testing;
