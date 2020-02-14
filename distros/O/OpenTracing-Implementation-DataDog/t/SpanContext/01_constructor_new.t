use Test::Most;

BEGIN {
    $ENV{OPENTRACING_INTERFACE} = 1 unless exists $ENV{OPENTRACING_INTERFACE};
}
#
# This breaks if it would be set to 0 externally, so, don't do that!!!


use strict;
use warnings;

use aliased 'OpenTracing::Implementation::DataDog::SpanContext';

use Types::Standard qw/is_Int/;



subtest 'new SpanContext with all parameters' => sub {
    
    my $test_span_context;
    
    lives_ok {
        $test_span_context = SpanContext->new(
            trace_id      => 12345,
            service_type  => 'web',
            service_name  => 'srvc name',
            resource_name => 'rsrc name',
            baggage_items => { foo => 1, bar => 2, trace_id => 67890 },
        )
    } "Created a SpanContext" ;
    
};



subtest 'new SpanContext with minimal parameters' => sub {
    
    my $test_span_context;
    
    lives_ok {
        $test_span_context = SpanContext->new(
            service_name  => 'srvc name',
            resource_name => 'rsrc name',
        )
    } "Created a SpanContext" ;
    
    ok ( is_Int( $test_span_context->trace_id ),
        "... and default 'trace_id' has been set to an 'Int'"
    );
    is ( $test_span_context->service_type, 'custom',
        "... and default 'service_type' has been set to 'custom'"
    );
    
};


# Regression Test
#
# these assertions are done by Type::Tiny constraints
#
subtest 'new SpanContext with errornous or missing parameters' => sub {
    
    my $test_span_context;
    
    
    note 'service_name';
    
    throws_ok {
        $test_span_context = SpanContext->new(
#           service_name  => 'srvc name',
            resource_name => 'rsrc name',
        )
    } qr/Missing required .* service_name/,
    "throws: Missing required 'service_name'" ;
    
    throws_ok {
        $test_span_context = SpanContext->new(
            service_name  => undef,
            resource_name => 'rsrc name',
        )
    } qr/Undef did not pass type constraint "Defined"/m,
    "throws: Type mismatch: for 'undef'" ;
    
    throws_ok {
        $test_span_context = SpanContext->new(
            service_name  => \"StringReference",
            resource_name => 'rsrc name',
        )
    } qr/Reference \\"StringReference" did not pass type constraint "Value"/m,
    "throws: Type mismatch: for reference" ;
    
    throws_ok {
        $test_span_context = SpanContext->new(
            service_name  => "",
            resource_name => 'rsrc name',
        )
    } qr/Must not be empty/m,
    "throws: Type mismatch: for empty string" ;
    
    
    note 'resource_name';
    
    throws_ok {
        $test_span_context = SpanContext->new(
            service_name  => 'srvc name',
#           resource_name => 'rsrc name',
        )
    } qr/Missing required .* resource_name/,
    "throws: Missing required 'resource_name'" ;
    
    throws_ok {
        $test_span_context = SpanContext->new(
            service_name  => 'srvc name',
            resource_name => undef,
        )
    } qr/Undef did not pass type constraint "Defined"/m,
    "throws: Type mismatch: for 'undef'" ;
    
    throws_ok {
        $test_span_context = SpanContext->new(
            service_name  => 'srvc name',
            resource_name => \"StringReference",
        )
    } qr/Reference \\"StringReference" did not pass type constraint "Value"/m,
    "throws: Type mismatch: for reference" ;
    
    throws_ok {
        $test_span_context = SpanContext->new(
            service_name  => 'srvc name',
            resource_name => "",
        )
    } qr/Must not be empty/m,
    "throws: Type mismatch: for empty string" ;
    
    
    note 'trace_id';
    
    throws_ok {
        $test_span_context = SpanContext->new(
            trace_id      => 'foo',
            service_name  => 'srvc name',
            resource_name => 'rsrc name',
        )
    } qr/Value "foo" did not pass type constraint "Int"/,
    "throws: Type mismatch: 'trace_id' must be 'Int'" ;
    
    
    note 'service_type';
    
    throws_ok {
        $test_span_context = SpanContext->new(
            service_type  => 'foo',
            service_name  => 'srvc name',
            resource_name => 'rsrc name',
        )
    } qr/Value "foo" did not pass type constraint "Enum\[.*\]/,
    "throws: Type mismatch: 'service_type' must be 'Enum'" ;
    
    lives_ok {
        $test_span_context = SpanContext->new(
            service_type  => $_,
            service_name  => 'srvc name',
            resource_name => 'rsrc name',
        )
    }
    "... but is okay when service_type is '$_'"
    foreach qw/web db cache custom/;
};






done_testing;
