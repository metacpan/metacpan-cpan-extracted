#!/usr/bin/env perl

use v5.30; # For the test case

use Test2::V0 -target => 'OpenTelemetry::Instrumentation::namespace';
use Test2::Tools::Spec;
use Test2::Tools::OpenTelemetry;
use OpenTelemetry::Constants -span;

use experimental 'signatures';
use lib 't/lib';

my $span;
my $otel = mock 'OpenTelemetry::Trace::Tracer' => override => [
    create_span => sub ( $, %args ) {
        $span = mock { otel => \%args } => add => [
            set_attribute => sub ( $self, %args ) {
                $self->{otel}{attributes} = {
                    %{ $self->{otel}{attributes} // {} },
                    %args,
                };
            },
            set_status => sub ( $self, $status, $desc = '' ) {
                return if defined $self->{otel}{status};

                $self->{otel}{status} = {
                    code => $status,
                    $desc ? ( description => $desc ) : (),
                };
            },
            record_exception => sub ( $self, $e, %attributes ) {
                push @{ $self->{otel}{exceptions} //= [] }, {
                    exception  => $e,
                    attributes => \%attributes,
                };
            },
            end => sub ( $self ) {
                $self->{otel}{ended} = 1;
            },
        ];
    },
];

no_messages {
    ok CLASS->install, 'Does nothing without rules';
};

describe 'Explicit config' => sub {
    require Local::Loaded::Secret;
    require Local::Loaded::Before;

    my $logs = messages {
        CLASS->install(
            qr/^Local::Loaded::Secret\b/ => 0,
            qr/^Local::Loaded::/         => 1,
        );
    };

    is [ sort { $a->[-1] cmp $b->[-1] } grep { $_->[0] eq 'info' } @$logs ] => [
        [
            info => 'OpenTelemetry',
            'Adding OpenTelemetry auto-instrumentation for Local::Loaded::Before::die',
        ],
        [
            info => 'OpenTelemetry',
            'Adding OpenTelemetry auto-instrumentation for Local::Loaded::Before::do',
        ],
    ], 'Logged info about auto-instrumentation at install time';

    is messages {
        require Local::Loaded::After;
    } => array {
        filter_items { grep $_->[0] eq 'info', @_ };
        item [
            info => 'OpenTelemetry',
            'Adding OpenTelemetry auto-instrumentation for Local::Loaded::After::do',
        ];
        end;
    }, 'Logged info about auto-instrumentation at runtime';

    before_each Reset => sub { delete $span->{otel} };

    tests 'Loaded before' => sub {
        ok Local::Loaded::Before::do(), 'Before returns as expected';
        is $span->{otel}, {
            ended  => T,
            name   => 'Local::Loaded::Before::do',
            parent => D,
            status => { code => SPAN_STATUS_OK },
        }, 'Captured module loaded before install';
    };

    tests 'Funtion that dies' => sub {
        like dies { Local::Loaded::Before::die() }, qr/oops/,
            'Before returns as expected';

        is $span->{otel}, {
            ended  => T,
            name   => 'Local::Loaded::Before::die',
            parent => D,
            exceptions => [
                {
                    attributes => {},
                    exception  => match qr/^oops/,
                },
            ],
            status => {
                code        => SPAN_STATUS_ERROR,
                description => 'oops',
            },
        }, 'Captured module loaded before install';
    };

    tests 'Loaded after' => sub {
        ok Local::Loaded::After::do(), 'After returns as expected';
        is $span->{otel}, {
            ended  => T,
            name   => 'Local::Loaded::After::do',
            parent => D,
            status => { code => SPAN_STATUS_OK },
        }, 'Captured module loaded after install';
    };

    tests 'Not instrumented' => sub {
        ok Local::Loaded::Secret::do(), 'After returns as expected';
        is $span->{otel}, U;
    };
};

describe 'Config from file' => sub {
    require Local::File;

    my $logs = messages {
        CLASS->install(
            -from_file => 't/share/namespace.yaml',
        );
    };

    is [ sort { $a->[-1] cmp $b->[-1] } grep { $_->[0] ne 'trace' } @$logs ] => [
        [
            info => 'OpenTelemetry',
            'Adding OpenTelemetry auto-instrumentation for Local::File::die',
        ],
        [
            info => 'OpenTelemetry',
            'Adding OpenTelemetry auto-instrumentation for Local::File::do',
        ],
    ], 'Logged info about auto-instrumentation at install time';

    before_each Reset => sub { delete $span->{otel} };

    tests 'Loaded from file' => sub {
        ok Local::File::do(), 'Before returns as expected';
        is $span->{otel}, {
            ended  => T,
            name   => 'Local::File::do',
            parent => D,
            status => { code => SPAN_STATUS_OK },
        }, 'Captured module loaded before install';
    };
};

done_testing;
