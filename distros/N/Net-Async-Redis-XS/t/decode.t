use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Net::Async::Redis::XS;

my $instance = Net::Async::Redis::Protocol::XS->new(
    error  => sub { note 'error callback: ' . shift },
    pubsub => sub { note 'pubsub callback: ' . shift },
);

++$|;
like(exception {
    Net::Async::Redis::XS::decode_buffer($instance, [])
}, qr/expected a string/, 'complains about bad types');
like(exception {
    Net::Async::Redis::XS::decode_buffer($instance, {})
}, qr/expected a string/, 'complains about bad types');

our $Z = "\x0D\x0A";
is(Net::Async::Redis::XS::decode_buffer($instance, ":3$Z"), 3, 'can decode_buffer');
is(Net::Async::Redis::XS::decode_buffer($instance, ":-2$Z"), -2, 'can decode_buffer');
is(Net::Async::Redis::XS::decode_buffer($instance, ":0$Z"), 0, 'can decode_buffer');
isnt(Net::Async::Redis::XS::decode_buffer($instance, ":23$Z"), 22, 'can decode_buffer');
is(Net::Async::Redis::XS::decode_buffer($instance, ",1$Z"), 1, 'floating point');
is(Net::Async::Redis::XS::decode_buffer($instance, ",1.0$Z"), 1.0, 'floating point');
is(Net::Async::Redis::XS::decode_buffer($instance, ",1.00$Z"), 1.00, 'floating point');
cmp_ok(abs(Net::Async::Redis::XS::decode_buffer($instance, ",1.00384$Z") - 1.00384), '<=', 0.0001, 'floating point');
cmp_ok(abs(Net::Async::Redis::XS::decode_buffer($instance, ",-3.14156926535898$Z") - -3.14156926535898), '<=', 0.000001, 'floating point');
is(Net::Async::Redis::XS::decode_buffer($instance, "+example$Z"), 'example', 'can decode_buffer');
is(Net::Async::Redis::XS::decode_buffer($instance, "-error$Z"), undef, 'can decode_buffer');
is_deeply(Net::Async::Redis::XS::decode_buffer($instance, "*1$Z+test$Z"), ['test'], 'can decode_buffer');
is_deeply(Net::Async::Redis::XS::decode_buffer($instance, "*1$Z*1$Z+test$Z"), [['test']], 'can decode_buffer');

is_deeply([ Net::Async::Redis::XS::decode_buffer($instance, ":18$Z") ], [ 18 ], 'integer should yield one item');
is_deeply([ Net::Async::Redis::XS::decode_buffer($instance, "*0$Z") ], [ [ ] ], 'empty array');
is_deeply([ Net::Async::Redis::XS::decode_buffer($instance, "*1$Z*0$Z") ], [ [ [] ] ], 'empty array inside another array');
is_deeply([ Net::Async::Redis::XS::decode_buffer($instance, "*1$Z*1$Z*0$Z") ], [ [ [ [] ] ] ], 'empty array inside two arrays');
{
    my $err;
    local $instance->{error} = sub { fail('called more than once') if $err; $err = shift; };
    is_deeply([ Net::Async::Redis::XS::decode_buffer($instance, "-error$Z") ], [ ], 'error should yield no items');
    is($err, 'error', 'callback received error message');
}

{
    my $target = "*1$Z*1$Z*2$Z:8$Z*6$Z+a$Z+1$Z+b$Z+2$Z+c$Z";
    for(0..length($target)) {
        my $data = substr($target, 0, $_);
        is_deeply(
            [ Net::Async::Redis::XS::decode_buffer(
                $instance,
                $data,
            ) ], [ ], 'empty response on partial input',
        );
        is(
            Net::Async::Redis::XS::decode_buffer(
                $instance,
                $data,
            ), undef, 'empty response on partial input',
        );
    }
}
is_deeply(
    Net::Async::Redis::XS::decode_buffer($instance,
        "*1$Z*1$Z*2$Z:8$Z*6$Z+a$Z+1$Z+b$Z+2$Z+c$Z+3$Z"
    ), [
        [
            [
                8, [
                    'a', '1', 'b', '2', 'c', '3'
                ]
            ]
        ]
    ],
    'can decode_buffer'
);

{
    my $pubsub;
    local $instance->{pubsub} = sub { fail('called more than once') if $pubsub; $pubsub = shift; };
    is_deeply([ Net::Async::Redis::XS::decode_buffer($instance, ">1$Z:8$Z") ], [ ], 'can decode_buffer for pubsub with no data');
    is_deeply($pubsub, [ 8 ]);
}

is_deeply(
    Net::Async::Redis::XS::decode_buffer($instance,
        "*1$Z*1$Z*1$Z%0$Z"
    ), [
        [
            [ [ ] ]
        ]
    ],
    'can decode_buffer'
);
done_testing;

