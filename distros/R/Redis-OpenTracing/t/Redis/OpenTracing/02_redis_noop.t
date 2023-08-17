use Test::Most;

use strict;
use warnings;

use lib 't/lib';

use Test::Mock::Redis::NoOp;

subtest "Check 'Test:Mock::Redis::NoOp'" => sub {
    
    my $redis_mock = Test::Mock::Redis::NoOp->mock_new( );
    isa_ok( $redis_mock, 'Test::Mock::Redis::NoOp', "Result of 'mock_new' call" );
    
    my @vals = ();
    my $cntr = 0;
    
    lives_ok {
        $redis_mock->connect( server => '127.0.0.1' );
        $redis_mock->ping;
        $redis_mock->set( my_key => "Hello Redis" );
        @vals = $redis_mock->keys( "*" );
        $cntr = $redis_mock->keys( "*" );
        
    } "... and it handles some methods";
    
    is scalar @vals, 3, "... and 'keys' does return 3 values";
    is        $cntr, 3, "... and 'keys' does return the count of elements";
    
    Test::Mock::Redis::NoOp->mock_cmp_calls( $redis_mock, [
        connect => [ $redis_mock, 'server', '127.0.0.1' ],
        ping    => [ $redis_mock ],
        set     => [ $redis_mock, 'my_key', 'Hello Redis' ],
        keys    => [ $redis_mock, "*" ],
        keys    => [ $redis_mock, "*" ],
    ], "... and each gets the right arguments");
    
};

done_testing( );

1;
