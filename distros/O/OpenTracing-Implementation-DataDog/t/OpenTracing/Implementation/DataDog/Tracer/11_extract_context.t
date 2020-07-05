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
    lives_ok {
        $test_span_context = $test_tracer
            ->extract_context(
                'CARRIER_FORMAT',
                bless( { foo => 0, bar => [ 1, 2 ] }, 'MyStub::Carrier' )
            )
        #
        # XXX: this needs a FORMAT and a carrier
    } "... and can call 'extract_context'";
    
    ok !defined $test_span_context,
        "... but returns 'undef'"
};



done_testing( );



package MyStub::Carrier;

sub foo { ... }
