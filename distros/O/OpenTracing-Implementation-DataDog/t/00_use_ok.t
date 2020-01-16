use Test::Most;

BEGIN {
    use_ok('OpenTracing::Implementation::DataDog');
    use_ok('OpenTracing::Implementation::DataDog::Agent');
    use_ok('OpenTracing::Implementation::DataDog::Scope');
    use_ok('OpenTracing::Implementation::DataDog::ScopeManager');
    use_ok('OpenTracing::Implementation::DataDog::Span');
    use_ok('OpenTracing::Implementation::DataDog::SpanContext');
    use_ok('OpenTracing::Implementation::DataDog::Tracer');
    use_ok('OpenTracing::Implementation::DataDog::Utils');
};

done_testing;
