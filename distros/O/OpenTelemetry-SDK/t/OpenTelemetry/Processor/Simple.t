#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::Processor::Simple';
use Test2::Tools::Spec;
use Test2::Tools::OpenTelemetry;

use lib 't/lib';
use Local::Exporter;

like dies { CLASS->new },
    qr/Required parameter 'exporter' is missing/,
    'Exporter is mandatory';

like dies { CLASS->new( exporter => mock ) },
    qr/Exporter must implement.*: Test2::Tools::Mock/,
    'Exporter is validated';

is CLASS->new( exporter => Local::Exporter->new ), object {
    prop isa => $CLASS;
}, 'Can construct processor';

describe shutdown => sub {
    my ( $timeout, $exporter, $processor );

    before_each Create => sub {
        $exporter  = Local::Exporter->new;
        $processor = CLASS->new( exporter => $exporter );
    };

    case 'With timeout' => sub { $timeout = 123 };
    case 'No timeout'   => sub { undef $timeout };

    tests force_flush => sub {
        is $processor->force_flush( $timeout ? $timeout : () )->get, 1,
            'Called';

        is $exporter->calls, [ [ force_flush => $timeout ] ],
            'Propagated to exporter';
    };

    tests shutdown => sub {
        is $processor->shutdown( $timeout ? $timeout : () )->get, 1,
            'Called';

        is $exporter->calls, [ [ shutdown => $timeout ] ],
            'Propagated to exporter';
    };
};

done_testing;
