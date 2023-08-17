use Test::Most;

BEGIN {
    use Module::Loaded;
    mark_as_loaded( OpenTracing::Implementation::NoOp::Tracer )
}

use OpenTracing::Implementation;



subtest 'can import' => sub {
    
    can_ok( 'OpenTracing::Implementation' => 'import' );
    
};

subtest 'can bootstrap_global_tracer' => sub {
    
    can_ok( 'OpenTracing::Implementation' => 'bootstrap_global_tracer' );
    
};



done_testing;
