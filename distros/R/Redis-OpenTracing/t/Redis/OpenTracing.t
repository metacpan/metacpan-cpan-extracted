use Test::More;

use OpenTracing::Implementation qw/Test/;

use Test::OpenTracing::Integration;
use Test::Mock::Redis;
use Test::Deep qw/re superhashof/;;

use Redis::OpenTracing;



# create your 'wrapped' Redis client
#
my $redis = Redis::OpenTracing->new(
    redis => Test::Mock::Redis->new(),
    tags  => { tag_1 => 1, tag_2 => 2},
);



# do your usual stud, as always
#
$redis->ping;
$redis->set( key_1 => "Hello" );
$redis->multi;
$redis->rpush( key_2 => 1 .. 5 );
$redis->hset( key_3 => foo => 7, bar => 8);
my @resp = $redis->exec;
my @keys = $redis->keys('*');
eval { $redis->dies; };

pass "so far, so good!";

# and now see that we have spans
#
global_tracer_cmp_spans(
    [
        {
            operation_name  => "Test::Mock::Redis::ping",
            tags            => {
                'component'     => "Test::Mock::Redis",
                'db.statement'  => "PING",
                'db.type'       => "redis",
                'span.kind'     => "client",
                'tag_1'         => "1",
                'tag_2'         => "2",
            },
        },
        {
            operation_name  => "Test::Mock::Redis::set",
            tags            => superhashof( {
                'db.statement'  => "SET",
            } ),
        },
        {
            operation_name  => "Test::Mock::Redis::multi",
            tags            => superhashof( {
                'db.statement'  => "MULTI",
            } ),
        },
        {
            operation_name  => "Test::Mock::Redis::rpush",
            tags            => superhashof( {
                'db.statement'  => "RPUSH",
            } ),
        },
        {
            operation_name  => "Test::Mock::Redis::hset",
            tags            => superhashof( {
                'db.statement'  => "HSET",
            } ),
        },
        {
            operation_name  => "Test::Mock::Redis::exec",
            tags            => superhashof( {
                'db.statement'  => "EXEC",
            } ),
        },
        {
            operation_name  => "Test::Mock::Redis::keys",
            tags            => superhashof( {
                'db.statement'  => "KEYS",
            } ),
        },
        {
            operation_name  => "Test::Mock::Redis::dies",
            tags            => superhashof( {
                'component'     => "Test::Mock::Redis",
                'db.statement'  => "DIES",
                'db.type'       => "redis",
                'span.kind'     => "client",
                'tag_1'         => "1",
                'tag_2'         => "2",

                'error'         => 1,
                'error.kind'    => "REDIS_EXCEPTION",
                'message'       => re(qr/Can't locate object method "dies".../)
            } ),
        },
    ],
   "... and we do have spans" 
);



done_testing();
