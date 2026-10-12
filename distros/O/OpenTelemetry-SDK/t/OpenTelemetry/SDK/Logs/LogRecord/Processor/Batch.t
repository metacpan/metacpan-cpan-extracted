#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::SDK::Logs::LogRecord::Processor::Batch';
use Test2::Tools::Spec;
use Test2::Tools::OpenTelemetry;

use OpenTelemetry::Constants -trace_export;

use lib 't/lib';
use Local::Exporter::File;

local %ENV = (
    %ENV,
    OTEL_PERL_BSP_MAX_WORKERS => 1,
);

describe on_emit => sub {
    my ( $log_record, @calls, @logs );

    case 'Log' => sub {
        $log_record = 'my-log';
        @calls = (
            [ export   => [ 'my-log', 'my-log' ], 30_000 ],
            [ 'shutdown' ],
        );
    };

    it Works => { flat => 1 } => sub {
        my $exporter  = Local::Exporter::File->new;
        my $processor = CLASS->new(
            batch_size => 2,
            queue_size => 2,
            exporter   => $exporter,
        );

        no_messages {
            is $processor->on_emit($log_record), U, 'Returns undefined';
        };

        is $exporter->calls, [], 'Nothing exported yet';

        no_messages {
            is $processor->on_emit($log_record), U, 'Returns undefined';
        };

        # Make sure we wait before reading the calls
        $processor->shutdown->get;

        is $exporter->calls, \@calls, 'Correct calls on exporter';
    };
};

done_testing;
