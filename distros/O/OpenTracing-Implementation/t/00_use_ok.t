use Test::Most;

BEGIN {
    use Module::Loaded;
    mark_as_loaded( OpenTracing::Implementation::NoOp::Tracer )
}

BEGIN { use_ok('OpenTracing::Implementation') };

done_testing;
