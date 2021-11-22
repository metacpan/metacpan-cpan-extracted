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

my @events;
$pubsub->on(error      => sub { shift; push @events, [error      => @_] });
$pubsub->on(psubscribe => sub { shift; push @events, [psubscribe => @_] });
$pubsub->on(subscribe  => sub { shift; push @events, [subscribe  => @_] });

is ref($pubsub->listen("rtest:$$:1" => \&gather)), 'CODE', 'listen';
$pubsub->listen("rtest:$$:2" => \&gather);
note 'Waiting for subscriptions to be set up...';
Mojo::IOLoop->timer(0.15 => sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;
memory_cycle_ok($redis, 'cycle ok after listen');

$pubsub->notify("rtest:$$:1" => 'message one');
$db->publish_p("rtest:$$:2" => 'message two')->wait;
memory_cycle_ok($redis, 'cycle ok after notify');

is_deeply [sort @messages], ['message one', 'message two'], 'got messages' or diag join ", ", @messages;

$pubsub->channels_p('rtest*')->then(sub { @res = @_ })->wait;
is_deeply [sort @{$res[0]}], ["rtest:$$:1", "rtest:$$:2"], 'channels_p';

$pubsub->numsub_p("rtest:$$:1")->then(sub { @res = @_ })->wait;
is_deeply $res[0], {"rtest:$$:1" => 1}, 'numsub_p';

$pubsub->numpat_p->then(sub { @res = @_ })->wait;
is_deeply $res[0], 0, 'numpat_p';

is $pubsub->unlisten("rtest:$$:1", \&gather), $pubsub, 'unlisten';
memory_cycle_ok($pubsub, 'cycle ok after unlisten');
$db->publish_p("rtest:$$:1" => 'nobody is listening to this');

note 'Making sure the last message is not received';
Mojo::IOLoop->timer(0.15 => sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;
is_deeply [sort @messages], ['message one', 'message two'], 'got messages' or diag join ", ", @messages;

note 'test listen patterns';
@messages = ();
$pubsub->listen("rtest:$$:*" => \&gather);
Mojo::IOLoop->timer(
  0.2 => sub {
    $pubsub->notify("rtest:$$:4" => 'message four');
    $pubsub->notify("rtest:$$:5" => 'message five');
  }
);
Mojo::IOLoop->start;

is_deeply [sort @messages], ['message five', 'message four'], 'got messages' or diag join ", ", @messages;
$pubsub->unlisten("rtest:$$:*");

my $conn = $pubsub->connection;
is @{$conn->subscribers('response')}, 1, 'only one message subscriber';

undef $pubsub;
delete $redis->{pubsub};
isnt $redis->db->connection, $conn, 'pubsub connection cannot be re-used';

note 'test json data';
@messages = ();
$pubsub   = $redis->pubsub;
$pubsub->json("rtest:$$:1");
$pubsub->listen("rtest:$$:1" => \&gather);
Mojo::IOLoop->timer(
  0.2 => sub {
    $pubsub->notify("rtest:$$:1" => {some => 'data'});
    $pubsub->notify("rtest:$$:1" => 'just a string');
  }
);
Mojo::IOLoop->start;
is_deeply \@messages, [{some => 'data'}, 'just a string'], 'got json messages';

is_deeply [sort { $a cmp $b } map { $_->[0] } @events], [qw(psubscribe subscribe subscribe)], 'events';

done_testing;

sub gather {
  push @messages, $_[1];
  Mojo::IOLoop->stop if @messages == 2;
}
