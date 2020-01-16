use Test::Most;

use OpenTracing::AutoScope qw/start_guarded_span/;



subtest 'can start_guarded_span' => sub {
    
    can_ok( 'OpenTracing::AutoScope' => 'start_guarded_span' );
    
#   can_ok( __PACKAGE__, 'start_guarded_span' );
};



done_testing;
