use Test::Most;

use strict;
use warnings;

use OpenTracing::Implementation qw/Test/;
use Test::OpenTracing::Integration;

subtest "Create some traces" => sub {
    
    reset_spans;
    
    my $test_object = bless {}, 'MyTestApp';
    
    $test_object->get_some_keys( );
    
    global_tracer_cmp_easy(
        [
            {
                operation_name => 'MyTestApp::get_some_keys',
            },
            {
                operation_name => re( qr/Test::Mock::Redis::NoOp::keys$/ ),
                tags           => {
                    'component'     => 'Test::Mock::Redis::NoOp',
                    'db.statement'  => 'KEYS',
                    'db.type'       => 'redis',
#                   'peer.address'  => undef, # but will not be present at all
                    'span.kind'     => 'client',
                    'foo'           => '1',
                    'bar'           => '2',
                }
            },
        ],
        "Got some expected spans"
    )
};

done_testing;



package MyTestApp;

use strict;
use warnings;

use lib 't/lib';

use OpenTracing::AutoScope;
use Redis::OpenTracing;
use Test::Mock::Redis::NoOp;

sub get_some_keys{
    OpenTracing::AutoScope->start_guarded_span( );
    
    my $self = shift;
    
    my $redis_test = Redis::OpenTracing->new(
        redis => Test::Mock::Redis::NoOp->mock_new( ),
        tags => { foo => 1, bar => 2 }
    );
    
    return $redis_test->keys( );
    
}



1;
