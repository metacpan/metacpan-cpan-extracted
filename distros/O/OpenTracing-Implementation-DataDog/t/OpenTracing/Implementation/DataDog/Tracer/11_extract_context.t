use Test::Most;


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
                bless( { foo => 0, bar => [ 1, 2 ] }, 'HTTP::Headers' )
            )
        #
        # XXX: this needs a FORMAT and a carrier
    } "... and can call 'extract_context'";
    
    ok !defined $test_span_context,
        "... but returns 'undef'"
};



done_testing( );
