use strict;
use warnings;
use Test2::V0;

use Net::Async::NATS::Subscription;

my $cb = sub { };

my $sub = Net::Async::NATS::Subscription->new(
    sid      => 42,
    subject  => 'test.>',
    queue    => 'workers',
    callback => $cb,
);

is $sub->sid, 42, 'sid';
is $sub->subject, 'test.>', 'subject';
is $sub->queue, 'workers', 'queue';
is $sub->callback, $cb, 'callback';
is $sub->max_msgs, undef, 'max_msgs defaults to undef';

my $sub2 = Net::Async::NATS::Subscription->new(
    sid      => 1,
    subject  => 'foo',
    callback => $cb,
    max_msgs => 5,
);

is $sub2->max_msgs, 5, 'max_msgs set';
is $sub2->queue, undef, 'queue undef when not set';

done_testing;
