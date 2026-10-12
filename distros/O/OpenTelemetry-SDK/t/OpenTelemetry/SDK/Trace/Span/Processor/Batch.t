#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::SDK::Trace::Span::Processor::Batch';
use Test2::Tools::Spec;
use Test2::Tools::OpenTelemetry;

use OpenTelemetry::Constants -trace_export;

use lib 't/lib';
use Local::Exporter::File;

local %ENV = (
    %ENV,
    OTEL_PERL_BSP_MAX_WORKERS => 1,
);

tests Validation => sub {
    local %ENV = (
        %ENV,
        OTEL_BSP_MAX_EXPORT_BATCH_SIZE => 100,
        OTEL_BSP_MAX_QUEUE_SIZE        =>  50,
    );

    is messages {
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

describe on_end => sub {
    my ( $span, $sampled, @calls, @logs );

    before_case Reset => sub {
        $sampled = 1;
        @logs    = ();
        @calls   = [ 'shutdown' ];

        $span = mock {} => add => [
            snapshot => 'snapshot',
            context  => sub {
                mock {} => add => [
                    trace_flags => sub {
                        mock {} => add => [ sampled => $sampled ];
                    },
                ];
            },
        ];
    };

    case 'Sampled span' => sub {
        @calls = (
            [ export   => [ 'snapshot', 'snapshot' ], 30_000 ],
            [ 'shutdown' ],
        );
    };

    case 'Unsampled span' => sub {
        $sampled = 0;
    };

    it Works => { flat => 1 } => sub {
        my $exporter  = Local::Exporter::File->new;
        my $processor = CLASS->new(
            batch_size => 2,
            queue_size => 2,
            exporter   => $exporter,
        );

        is messages {
            is $processor->on_end($span), U, 'Returns undefined';
        } => \@logs, 'Logged expected messages';

        is $exporter->calls, [], 'Nothing exported yet';

        is messages {
            is $processor->on_end($span), U, 'Returns undefined';
        } => \@logs, 'Logged expected messages';

        # Make sure we wait before reading the calls
        $processor->shutdown->get;

        is $exporter->calls, \@calls, 'Correct calls on exporter';
    };
};

done_testing;
