use Test::Most;

use strict;
use warnings;

use lib 't/lib';

use Test::Mock::Redis::NoOp;

use Redis::OpenTracing;

subtest "Check 'Redis::OpenTracing' respects context" => sub {
    
    my $redis_mock = Test::Mock::Redis::NoOp->mock_new( );
    my $redis_test = Redis::OpenTracing->new( redis => $redis_mock );
    ok( $redis_test, "Instantiated some 'Redis::OpenTracing' object" );
    
    my $keys = $redis_test->keys( '*' );
    is_deeply( \$keys, \'3',
        "... and returns a number in 'Scalar Context'"
    );
    
    my @keys = $redis_test->keys( '*' );
    is_deeply( \@keys, [ qw/foo bar baz/ ],
        "... and returns the elements in 'List Context'"
    );
    
};

done_testing( );

1;
