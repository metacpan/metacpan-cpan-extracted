use Test::Most;

BEGIN {
    use_ok('OpenTracing::Implementation::NoOp');
    use_ok('OpenTracing::Implementation::NoOp::Scope');
    use_ok('OpenTracing::Implementation::NoOp::ScopeManager');
    use_ok('OpenTracing::Implementation::NoOp::Span');
    use_ok('OpenTracing::Implementation::NoOp::SpanContext');
    use_ok('OpenTracing::Implementation::NoOp::Tracer');
};

done_testing;
