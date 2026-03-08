use strict;
use warnings;
use Test2::V0;

ok require Net::Async::NATS, 'loaded Net::Async::NATS';
ok require Net::Async::NATS::Subscription, 'loaded Net::Async::NATS::Subscription';

done_testing;
