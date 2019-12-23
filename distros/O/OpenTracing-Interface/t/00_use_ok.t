use Test::Most;

BEGIN {
    $ENV{OPENTRACING_INTERFACE} = !undef;

    use_ok('OpenTracing::Interface::Scope');
    use_ok('OpenTracing::Interface::ScopeManager');
    use_ok('OpenTracing::Interface::Span');
    use_ok('OpenTracing::Interface::SpanContext');
    use_ok('OpenTracing::Interface::Tracer');
};

done_testing;
