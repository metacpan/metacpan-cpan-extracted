#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::SDK::Trace::Span::Processor::Simple';
use Test2::Tools::Spec;
use Test2::Tools::OpenTelemetry;

use Object::Pad ':experimental(init_expr)';

class Local::Test :does(OpenTelemetry::Exporter) {
    use Future::AsyncAwait;

    field $calls :reader = [];
    method $log { push @$calls, [ @_ ] }

    method export { $self->$log( export=> @_ ); 1 }

    async method shutdown    { $self->$log( shutdown    => @_ ); 1 }
    async method force_flush { $self->$log( force_flush => @_ ); 1 }
}

like dies { CLASS->new },
    qr/Required parameter 'exporter' is missing/,
    'Exporter is mandatory';

like dies { CLASS->new( exporter => mock ) },
    qr/Exporter must implement.*: Test2::Tools::Mock/,
    'Exporter is validated';

is CLASS->new( exporter => Local::Test->new ), object {
    prop isa => $CLASS;
    call [ on_start => mock, mock ], U;
}, 'Can construct processor';

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
            my $exporter  = Local::Test->new;
            my $processor = CLASS->new( exporter => $exporter );

            no_messages {
                is $processor->on_end($span), U, 'Returns undefined';
            };

            is $exporter->calls, \@calls, 'Correct calls on exporter';
        };
    };

    tests 'Exceptions' => sub {
        my $exporter  = Local::Test->new;
        my $processor = CLASS->new( exporter => $exporter );
        my $span = mock {} => add => [ context => sub { die 'oops' } ];

        is messages {
            is $processor->on_end($span), U, 'Returns undefined';
        }, [
            [
                error => 'OpenTelemetry',
                match qr/unexpected error in .*->on_end - oops/,
            ],
        ], 'Logged error';

        is $exporter->calls, [], 'No calls on exporter';
    };
};

describe shutdown => sub {
    my ( $timeout, $exporter, $processor );

    before_each Create => sub {
        $exporter  = Local::Test->new;
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
