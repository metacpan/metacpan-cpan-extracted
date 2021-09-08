use Test::Most;

use strict;
use warnings;

use lib 't/lib';

use Test::Mock::Redis::NoOp;

use Redis::OpenTracing;

subtest "Check 'Redis::OpenTracing' with commonly known methods" => sub {
    
    my $redis_mock = Test::Mock::Redis::NoOp->mock_new( );
    my $redis_test = Redis::OpenTracing->new( redis => $redis_mock );
    ok( $redis_test, "Instantiated some 'Redis::OpenTracing' object" );
    
    lives_ok {
        $redis_test->connect( server => '127.0.0.1' );
        $redis_test->ping;
        $redis_test->set( my_key => "Hello Redis" );
    } "... and it handles some methods";
    
    Test::Mock::Redis::NoOp->mock_cmp_calls( $redis_mock, [
        connect => [ $redis_mock, 'server', '127.0.0.1' ],
        ping    => [ $redis_mock ],
        set     => [ $redis_mock, 'my_key', 'Hello Redis' ],
    ], "... and dispatched to internal client correctly");
    
};

done_testing( );

1;
