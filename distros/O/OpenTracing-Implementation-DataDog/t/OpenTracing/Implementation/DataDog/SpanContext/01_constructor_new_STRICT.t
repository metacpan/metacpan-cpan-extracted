use Test::Most;



BEGIN {
    $ENV{EXTENDED_TESTING} = !undef
}



use aliased 'OpenTracing::Implementation::DataDog::SpanContext';

use Types::Standard qw/is_Int/;



subtest 'new SpanContext with erroneous or missing parameters' => sub {
    
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
    
    
#   note 'trace_id';
#   
#   throws_ok {
#       $test_span_context = SpanContext->new(
#           trace_id      => 'foo',
#           service_name  => 'srvc name',
#           resource_name => 'rsrc name',
#       )
#   } qr/Value "foo" did not pass type constraint "Int"/,
#   "throws: Type mismatch: 'trace_id' must be 'Int'" ;
#   
#   there should be an entire different error, cause we can not set a trace_id!
    
    
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
