use Test::Most;

BEGIN {
    $ENV{OPENTRACING_INTERFACE} = !undef;

    use_ok('OpenTracing::Role::Scope');
    use_ok('OpenTracing::Role::ScopeManager');
    use_ok('OpenTracing::Role::Span');
    use_ok('OpenTracing::Role::SpanContext');
    use_ok('OpenTracing::Role::Tracer');
};

done_testing;
