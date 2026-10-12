#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Processor::Batch';
use Test2::Tools::Spec;
use Test2::Tools::OpenTelemetry;

use OpenTelemetry::Constants -trace;

use lib 't/lib';
use Local::Exporter::File;

tests Validation => sub {
    like dies { CLASS->new },
        qr/Required parameter 'exporter' is missing/,
        'Exporter is mandatory';

    like dies { CLASS->new( exporter => mock ) },
        qr/Exporter must implement.*: Test2::Tools::Mock/,
        'Exporter is validated';

    is CLASS->new( exporter => Local::Exporter::File->new ), object {
        prop isa => $CLASS;
    }, 'Can construct processor';

    is messages {
        local %ENV = (
            %ENV,
            OTEL_BSP_MAX_EXPORT_BATCH_SIZE => 100,
            OTEL_BSP_MAX_QUEUE_SIZE        =>  50,
        );

        is CLASS->new( exporter => Local::Exporter::File->new ),
            object { prop isa => $CLASS },
            'Constructed processor';
    }, [
        [
            warning => 'OpenTelemetry',
            match qr/greater than maximum queue size/,
        ],
    ], 'Logged mismatched environment values';
};

tests 'Flush queue' => sub {
    my $processor = CLASS->new(
        batch_size => 4,
        queue_size => 4,
        exporter   => Local::Exporter::File->new,
    );

    $processor->process({}) for 1..3;

    no_messages {
        is $processor->force_flush->get, TRACE_EXPORT_SUCCESS,
            'Flushing returns success';
    };

    $processor->shutdown->get;
};

tests 'Ignore calls on shutdown' => sub {
    my $processor = CLASS->new(
        exporter => my $exporter = Local::Exporter::File->new,
    );

    $processor->shutdown->get;
    is $exporter->calls, [ [ 'shutdown', U ] ], 'Calling shutdown propagates to exporter';
    $exporter->reset;

    is $processor->force_flush->get, TRACE_EXPORT_SUCCESS, 'force_flush returns success';
    is $processor->shutdown->get,    TRACE_EXPORT_SUCCESS, 'shutdown returns success';

    is $exporter->calls, [ ], 'No calls got to exporter after shutdown';
};

done_testing;
