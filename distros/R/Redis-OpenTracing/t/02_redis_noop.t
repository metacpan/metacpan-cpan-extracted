use Test::Most;

use strict;
use warnings;

use lib 't/lib';

use Test::Mock::Redis::NoOp;

subtest "Check 'Test:Mock::Redis::NoOp'" => sub {
    
    my $redis_mock = Test::Mock::Redis::NoOp->mock_new( );
    isa_ok( $redis_mock, 'Redis::NoOp', "Result of 'mock_new' call" );
    
    lives_ok {
        $redis_mock->connect( server => '127.0.0.1' );
        $redis_mock->ping;
        $redis_mock->set( my_key => "Hello Redis" );
    } "... and it handles some methods";
    
    Test::Mock::Redis::NoOp->mock_cmp_calls( $redis_mock, [
        connect => [ $redis_mock, 'server', '127.0.0.1' ],
        ping    => [ $redis_mock ],
        set     => [ $redis_mock, 'my_key', 'Hello Redis' ],
    ], "... and each gets the right arguments");
    
};

done_testing( );

1;
