#!/usr/bin/env perl

use Test2::V0 -target => 'OpenTelemetry::SDK::Trace::Tracer';
use Syntax::Keyword::Dynamically;
use OpenTelemetry::Trace;
use OpenTelemetry::Context;

subtest 'Untraced context' => sub {
    my $tracer = CLASS->new(
        name         => 'test',
        version      => '0.001',
        span_creator => sub { { 'TEST' => { @_ } } },
    );

    is $tracer->create_span( foo => 123 ) => {
        TEST => {
            name    => 'empty',
            foo     => 123,
            kind    => 1,
            context => D,
        },
    } => 'Delegates to span creator';

    {
        dynamically OpenTelemetry::Context->current
            = OpenTelemetry::Trace->untraced_context;

        is $tracer->create_span( foo => 123 ), object {
            prop isa => 'OpenTelemetry::Trace::Span';
        } => 'Does not delegate when not traced';
    }

    is $tracer->create_span( foo => 123 ) => {
        TEST => {
            name    => 'empty',
            foo     => 123,
            kind    => 1,
            context => D,
        },
    } => 'Goes back to delegating to span creator';
};

done_testing;
