use Mojo::Base -strict;
use Test::More;
use Mojo::Redis;

plan skip_all => 'TEST_ONLINE=redis://localhost' unless $ENV{TEST_ONLINE};
*memory_cycle_ok = eval 'require Test::Memory::Cycle;1' ? \&Test::Memory::Cycle::memory_cycle_ok : sub { };

my $redis = Mojo::Redis->new($ENV{TEST_ONLINE});
my $db    = $redis->db;
memory_cycle_ok($redis, 'cycle ok for Mojo::Redis');

my $pubsub = $redis->pubsub;
my (@messages, @res);
memory_cycle_ok($redis, 'cycle ok for Mojo::Redis::PubSub');

is ref($pubsub->listen("rtest:$$:1" => \&gather)), 'CODE', 'listen';
$pubsub->listen("rtest:$$:2" => \&gather);
note 'Waiting for subscriptions to be set up...';
Mojo::IOLoop->timer(0.15 => sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;
memory_cycle_ok($redis, 'cycle ok after listen');

$pubsub->notify("rtest:$$:1" => 'message one');
$db->publish_p("rtest:$$:2" => 'message two');
memory_cycle_ok($redis, 'cycle ok after notify');

Mojo::IOLoop->start;
is_deeply [sort @messages], ['message one', 'message two'], 'got messages' or diag join ", ", @messages;

$pubsub->channels_p('rtest*')->then(sub { @res = @_ })->wait;
is_deeply [sort @{$res[0]}], ["rtest:$$:1", "rtest:$$:2"], 'channels_p';

$pubsub->numsub_p("rtest:$$:1")->then(sub { @res = @_ })->wait;
is_deeply $res[0], {"rtest:$$:1" => 1}, 'numsub_p';

$pubsub->numpat_p->then(sub { @res = @_ })->wait;
is_deeply $res[0], 0, 'numpat_p';

is $pubsub->unlisten("rtest:$$:1"), $pubsub, 'unlisten';
memory_cycle_ok($pubsub, 'cycle ok after unlisten');
$db->publish_p("rtest:$$:1" => 'nobody is listening to this');

note 'Making sure the last message is not received';
Mojo::IOLoop->timer(0.15 => sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;
is_deeply [sort @messages], ['message one', 'message two'], 'got messages' or diag join ", ", @messages;

my $conn = $pubsub->connection;
is @{$conn->subscribers('response')}, 1, 'only one message subscriber';

undef $pubsub;
delete $redis->{pubsub};
isnt $redis->db->connection, $conn, 'pubsub connection cannot be re-used';

$redis  = Mojo::Redis->new('redis://localhost/5');
$pubsub = $redis->pubsub;
is $pubsub->_keyspace_key, '__keyevent@5__:* *', 'keyevent default wildcard';
is $pubsub->_keyspace_key({type => 'key*'}), '__key*@5__:* *', 'keyboth wildcard listen';
is $pubsub->_keyspace_key(foo => undef), '__keyspace@5__:foo *', 'keyspace foo';
is $pubsub->_keyspace_key(undef, 'del'), '__keyevent@5__:del *', 'keyevent del';
is $pubsub->_keyspace_key('foo', 'rename', {db => 1, key => 'x', op => 'y'}), '__keyspace@1__:foo rename',
  'keyspace foo rename and db';
is $pubsub->_keyspace_key({db => 0, key => 'foo', type => 'key*'}), '__key*@0__:foo *', 'key* db and type';

my $cb = $pubsub->keyspace_listen(undef, 'del', {db => 1}, sub { });
is ref($cb), 'CODE', 'keyspace_listen returns callback';
is_deeply $pubsub->{chans}{'__keyevent@1__:del *'}, [$cb], 'callback is set up';
is $pubsub->keyspace_unlisten(undef, 'del', {db => 1}, $cb), $pubsub, 'keyspace_unlisten with callback';
ok !$pubsub->{chans}{'__keyevent@1__:del *'}, 'callback is removed';
$pubsub->{chans}{'__keyevent@1__:del *'} = [$cb];
is $pubsub->keyspace_unlisten(undef, 'del', {db => 1}), $pubsub, 'keyspace_unlisten without callback';
ok !$pubsub->{chans}{'__keyevent@1__:del *'}, 'callback is removed';

done_testing;

sub gather {
  push @messages, $_[1];
  Mojo::IOLoop->stop if @messages == 2;
}
