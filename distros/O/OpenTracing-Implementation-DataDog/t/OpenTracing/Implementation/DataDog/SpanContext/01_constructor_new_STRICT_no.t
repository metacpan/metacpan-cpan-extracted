use Test::Most;



BEGIN {
    delete $ENV{$_}
        for qw/EXTENDED_TESTING AUTHOR_TESTING RELEASE_TESTING PERL_STRICT/
}



use aliased 'OpenTracing::Implementation::DataDog::SpanContext';

use Types::Standard qw/is_Int/;



subtest 'new SpanContext with erroneous or missing parameters' => sub {
    
    my $test_span_context;
    
    note 'service_name';
    
    # required attributes will alwyas be 'required'
    throws_ok {
        $test_span_context = SpanContext->new(
#           service_name  => 'srvc name',
            resource_name => 'rsrc name',
        )
    } qr/Missing required .* service_name/,
    "throws: Missing required 'service_name'" ;
        
    lives_ok {
        $test_span_context = SpanContext->new(
            service_name  => undef,
            resource_name => 'rsrc name',
        )
    }
    "lives ok: Type mismatch: for 'undef'" ;
    
    lives_ok {
        $test_span_context = SpanContext->new(
            service_name  => \"StringReference",
            resource_name => 'rsrc name',
        )
    }
    "lives ok: Type mismatch: for reference" ;
    
    lives_ok {
        $test_span_context = SpanContext->new(
            service_name  => "",
            resource_name => 'rsrc name',
        )
    }
    "lives ok: Type mismatch: for empty string" ;
    
    
    note 'resource_name';
    
    # required attributes will alwyas be 'required'
    throws_ok {
        $test_span_context = SpanContext->new(
            service_name  => 'srvc name',
#           resource_name => 'rsrc name',
        )
    } qr/Missing required .* resource_name/,
    "throws: Missing required 'resource_name'" ;
    
    lives_ok {
        $test_span_context = SpanContext->new(
            service_name  => 'srvc name',
            resource_name => undef,
        )
    }
    "lives ok: Type mismatch: for 'undef'" ;
    
    lives_ok {
        $test_span_context = SpanContext->new(
            service_name  => 'srvc name',
            resource_name => \"StringReference",
        )
    }
    "lives ok: Type mismatch: for reference" ;
    
    lives_ok {
        $test_span_context = SpanContext->new(
            service_name  => 'srvc name',
            resource_name => "",
        )
    }
    "lives ok: Type mismatch: for empty string" ;
    
    
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
    
    
    # `enum` checks remain valid, even when not under STRICT
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
