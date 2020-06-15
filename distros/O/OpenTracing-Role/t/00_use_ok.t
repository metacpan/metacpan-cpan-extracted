use Test::Most;

BEGIN {
    $ENV{OPENTRACING_INTERFACE} = !undef;
    
    use_ok('OpenTracing::Role');
    
};

done_testing;
