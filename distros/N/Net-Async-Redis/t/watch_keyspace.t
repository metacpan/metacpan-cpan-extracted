use strict;
use warnings;

use Test::More;

use Net::Async::Redis;
use IO::Async::Loop;

plan skip_all => 'set NET_ASYNC_REDIS_HOST env var to test' unless exists $ENV{NET_ASYNC_REDIS_HOST};

my $loop = IO::Async::Loop->new;
$loop->add(my $redis = Net::Async::Redis->new);
$loop->add(my $sub = Net::Async::Redis->new);
Future->needs_all(
    $redis->connect(
        host => $ENV{NET_ASYNC_REDIS_HOST} // '127.0.0.1',
    ),
    $sub->connect(
        host => $ENV{NET_ASYNC_REDIS_HOST} // '127.0.0.1',
    )
)->get;

note 'keyspace notifications';
my @notifications;
$sub->watch_keyspace(
    'testprefix-*',
    sub {
        push @notifications, { op => $_[0], key => $_[1] }
    }
)->get;

note "Set key";
$redis->set(xyz => 'test')->get;
note "Get key";
is($redis->get('xyz')->get, 'test');
note "Delete key";
is($redis->del('xyz')->get, 1, 'deleted a single key');
note "Get key";
ok(!$redis->exists('xyz')->get, 'no longer exists');
is(@notifications, 0);

$redis->set('testprefix-xyz' => 'test')->get;
is($redis->get('testprefix-xyz')->get, 'test');
is($redis->del('testprefix-xyz')->get, 1, 'deleted a single key');
$loop->delay_future(after => 0.75)->get;
{
    local $TODO = 'needs further PSUBSCRIBE testing';
    is(@notifications, 2);
}
done_testing;


