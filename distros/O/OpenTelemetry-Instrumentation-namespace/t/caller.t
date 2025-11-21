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

after_each Reset => sub { undef $span };

describe 'With explicit auto-instrumentation' => sub {
    require Local::Caller::Explicit;

    tests 'Success instrumented' => sub {
        ok Local::Caller::Explicit::do(), 'Function returns as expected';

        is $span->{otel}, {
            ended  => T,
            name   => 'Local::Caller::Explicit::do',
            parent => D,
            status => { code => SPAN_STATUS_OK },
        }, 'Captured trace';
    };

    tests 'Exception instrumented' => sub {
        like dies { Local::Caller::Explicit::die() },
            qr/^oops /, 'Function dies as expected';

        is $span->{otel}, {
            ended  => T,
            name   => 'Local::Caller::Explicit::die',
            parent => D,
            status => {
                code        => SPAN_STATUS_ERROR,
                description => 'oops',
            },
            exceptions => [
                {
                    attributes => {},
                    exception => "oops at t/lib/Local/Caller/Explicit.pm line 5.\n",
                },
            ],
        }, 'Captured trace';
    };

    tests 'Uninstrumented code' => sub {
        ok Local::Caller::Explicit::secret(), 'Function returns as expected';

        is $span->{otel}, U, 'Did not capture trace';
    };
};

describe 'With explicit auto-instrumentation' => sub {
    require Local::Caller::Implicit;

    tests 'Success instrumented' => sub {
        ok Local::Caller::Implicit::do(), 'Function returns as expected';

        is $span->{otel}, {
            ended  => T,
            name   => 'Local::Caller::Implicit::do',
            parent => D,
            status => { code => SPAN_STATUS_OK },
        }, 'Captured trace';
    };

    tests 'Exception instrumented' => sub {
        like dies { Local::Caller::Implicit::die() },
            qr/^oops /, 'Function dies as expected';

        is $span->{otel}, {
            ended  => T,
            name   => 'Local::Caller::Implicit::die',
            parent => D,
            status => {
                code        => SPAN_STATUS_ERROR,
                description => 'oops',
            },
            exceptions => [
                {
                    attributes => {},
                    exception => "oops at t/lib/Local/Caller/Implicit.pm line 5.\n",
                },
            ],
        }, 'Captured trace';
    };
};

done_testing;
