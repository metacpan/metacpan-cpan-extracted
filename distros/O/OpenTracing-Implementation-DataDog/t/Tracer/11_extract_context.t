use Test::Most;

BEGIN {
    $ENV{OPENTRACING_INTERFACE} = 1 unless exists $ENV{OPENTRACING_INTERFACE};
}
#
# This breaks if it would be set to 0 externally, so, don't do that!!!

use aliased 'OpenTracing::Implementation::DataDog::Tracer';

subtest 'No default_context or callback' => sub {
    
    my $test_tracer;
    lives_ok {
        $test_tracer = Tracer->new( );
    } "Can create a Tracer, without any attributes";
    
    my $test_span_context;
    throws_ok {
        $test_span_context = $test_tracer->extract_context( undef, undef )
        #
        # XXX: this needs a FORMAT and a carrier
    } qr/Can not construct a default SpanContext/,
    "... but than throws an exception when trying to 'extract_context'";
    
};



subtest 'With default_context but no callback' => sub {
    
    my $test_tracer;
    lives_ok {
        $test_tracer = Tracer->new(
            default_context => {
                service_name  => 'srvc name',
                resource_name => 'rsrc name',
            }
        );
    } "Can create a Tracer, with default_context";
    
    my $test_span_context;
    lives_ok {
        $test_span_context = $test_tracer->extract_context( undef, undef )
        #
        # XXX: this needs a FORMAT and a carrier
    }
    "... and does give a SpanContext";
    
};



subtest 'Without default_context but with callback' => sub {
    
    my $test_tracer;
    lives_ok {
        $test_tracer = Tracer->new(
            default_context_builder => sub {
                return {
                    service_name  => 'srvc call',
                    resource_name => 'rsrc call',
                }
            }
        );
    } "Can create a Tracer, with 'default_context_builder' callback";
    
    my $test_span_context;
    lives_ok {
        $test_span_context = $test_tracer->extract_context( undef, undef )
        #
        # XXX: this needs a FORMAT and a carrier
    }
    "... and does give a SpanContext created from a HashRef";
    
};



subtest 'Without default_context but with callback' => sub {
    
    my $test_tracer;
    lives_ok {
        $test_tracer = Tracer->new(
            default_context_builder => sub {
                return bless { },
                    "OpenTracing::Implementation::DataDog::SpanContext"
            }
        );
    } "Can create a Tracer, with 'default_context_builder' callback";
    
    my $test_span_context;
    lives_ok {
        $test_span_context = $test_tracer->extract_context( undef, undef )
        #
        # XXX: this needs a FORMAT and a carrier
    }
    "... and does give a SpanContext created from a blessed HashRef or object";
    
};



done_testing( );

