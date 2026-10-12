#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::SDK::Logs::LogRecord';
use Test2::Tools::OpenTelemetry;

use OpenTelemetry::Constants '-log';
use OpenTelemetry::SDK::InstrumentationScope;
use OpenTelemetry::SDK::Resource;
use OpenTelemetry::Trace;
use OpenTelemetry::X;

my $scope = OpenTelemetry::SDK::InstrumentationScope->new( name => 'test' );

like dies { CLASS->new },
    qr/^Required parameter .* is missing/,
    'Constructor has required parameters';

my %args = (
    attributes            => my $attributes = { foo => { bar => { baz => 123 } } },
    severity_text         => '' . LOG_LEVEL_WARN,
    severity_number       =>  0 + LOG_LEVEL_WARN,
    resource              => OpenTelemetry::SDK::Resource->new,
    instrumentation_scope => $scope,
    body                  => 'Reticulating splines',
);

is my $record = CLASS->new(%args) => object {
    # LogRecord attributes accept nested structures
    call attributes            => { foo => { bar => { baz => 123 } } };
    call timestamp             => U;
    call observed_timestamp    => T;
    call severity_text         => 'WARN';
    call severity_number       => 13;
    call resource              => object { prop isa => 'OpenTelemetry::SDK::Resource' };
    call instrumentation_scope => object { call name => 'test' };
    call body                  => 'Reticulating splines';
    call dropped_attributes    => 0; # TODO: hard-coded for now
    call trace_flags           => T;
    call trace_state           => T;
    call trace_id              => T;
    call hex_trace_id          => T;
    call span_id               => T;
    call hex_span_id           => T;
};

$attributes->{foo}{bar} = 123;

is $record->attributes => { foo => { bar => { baz => 123 } } },
    'Attributes are read only';

$record->attributes->{foo} = 'xxx';

is $record->attributes => { foo => { bar => { baz => 123 } } },
    'Attributes are read only';

subtest 'Structured body' => sub {
    is my $log = CLASS->new( %args, body => { text => 'Foo' } ) => object {
        call body => { text => 'Foo' };
    }, 'Body can be structured';

    $log->body->{bar} = 'oops';

    is $log->body => { text => 'Foo' },
        'Body is read only';
};

done_testing;
