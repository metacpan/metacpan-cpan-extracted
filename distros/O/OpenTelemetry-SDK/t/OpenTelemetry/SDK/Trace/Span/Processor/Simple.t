#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::SDK::Trace::Span::Processor::Simple';
use Test2::Tools::Spec;
use Test2::Tools::OpenTelemetry;

use lib 't/lib';
use Local::Exporter;

describe on_end => sub {
    my ( $sampled, @calls );

    my $span = mock {} => add => [
        snapshot => 'snapshot',
        context  => sub {
            mock {} => add => [
                trace_flags => sub {
                    mock {} => add => [ sampled => $sampled ];
                },
            ];
        },
    ];

    describe 'Valid cases' => sub {
        case 'Sampled span' => sub {
            $sampled = 1;
            @calls = (
                [ export => [ 'snapshot' ] ],
            );
        };

        case 'Unsampled span' => sub {
            $sampled = 0;
            @calls = ();
        };

        it Works => { flat => 1 } => sub {
            my $exporter  = Local::Exporter->new;
            my $processor = CLASS->new( exporter => $exporter );

            no_messages {
                is $processor->on_end($span), U, 'Returns undefined';
            };

            is $exporter->calls, \@calls, 'Correct calls on exporter';
        };
    };
};

done_testing;
