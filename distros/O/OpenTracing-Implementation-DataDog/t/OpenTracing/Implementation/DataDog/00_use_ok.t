use Test::Most;

BEGIN {
    use_ok('OpenTracing::Implementation::DataDog');
    use_ok('OpenTracing::Implementation::DataDog::ScopeManager');
    use_ok('OpenTracing::Implementation::DataDog::Span');
    use_ok('OpenTracing::Implementation::DataDog::Utils');
};

done_testing;
