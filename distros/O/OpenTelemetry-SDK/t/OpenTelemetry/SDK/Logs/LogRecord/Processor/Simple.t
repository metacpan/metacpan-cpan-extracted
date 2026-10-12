#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::SDK::Logs::LogRecord::Processor::Simple';
use Test2::Tools::OpenTelemetry;
use Test2::Tools::Spec;

use lib 't/lib';
use Local::Exporter;

describe on_emit => sub {
    my @calls;

    my $log_record = mock;

    case 'Log Record' => sub {
        @calls = (
            [ export => [ $log_record ] ],
        );
    };

    it Works => { flat => 1 } => sub {
        my $exporter  = Local::Exporter->new;
        my $processor = CLASS->new( exporter => $exporter );

        no_messages {
            is $processor->on_emit($log_record), U, 'Returns undefined';
        };

        is $exporter->calls, \@calls, 'Correct calls on exporter';
    };
};

done_testing;
