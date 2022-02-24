use Mojo::Base -strict;
use Test::More;
use Mojo::JSON qw(encode_json);
use Mojo::Redis;

plan skip_all => 'TEST_ONLINE=redis://localhost' unless $ENV{TEST_ONLINE};
*memory_cycle_ok
  = eval 'require Test::Memory::Cycle;1' ? \&Test::Memory::Cycle::memory_cycle_ok : sub { ok 1, 'memory_cycle_ok' };

my $redis  = Mojo::Redis->new($ENV{TEST_ONLINE});
my $db     = $redis->db;
my $pubsub = $redis->pubsub;
my (@events, @messages, @res);

subtest memory => sub {
  memory_cycle_ok($redis, 'cycle ok for Mojo::Redis');
  memory_cycle_ok($redis, 'cycle ok for Mojo::Redis::PubSub');
};

subtest events => sub {
  $pubsub->on(error      => sub { shift; push @events, [error      => @_] });
  $pubsub->on(psubscribe => sub { shift; push @events, [psubscribe => @_] });
  $pubsub->on(subscribe  => sub { shift; push @events, [subscribe  => @_] });

  is ref($pubsub->listen("rtest:$$:1" => \&gather)), 'CODE', 'listen';
  $pubsub->listen("rtest:$$:2" => \&gather);
  note 'Waiting for subscriptions to be set up...';
  Mojo::Promise->timer(0.15)->wait;
  memory_cycle_ok($redis, 'cycle ok after listen');
};

subtest notify => sub {
  $pubsub->notify("rtest:$$:1" => 'message one');
  $db->publish_p("rtest:$$:2" => 'message two')->wait;
  memory_cycle_ok($redis, 'cycle ok after notify');
  has_messages("rtest:$$:1/message one", "rtest:$$:2/message two");
};

subtest channels => sub {
  $pubsub->channels_p('rtest*')->then(sub { @res = @_ })->wait;
  is_deeply [sort @{$res[0]}], ["rtest:$$:1", "rtest:$$:2"], 'channels_p';
};

subtest numsub => sub {
  $pubsub->numsub_p("rtest:$$:1")->then(sub { @res = @_ })->wait;
  is_deeply $res[0], {"rtest:$$:1" => 1}, 'numsub_p';
};

subtest numpat => sub {
  $pubsub->numpat_p->then(sub { @res = @_ })->wait;
  is_deeply $res[0], 0, 'numpat_p';
};

subtest unlisten => sub {
  is $pubsub->unlisten("rtest:$$:1", \&gather), $pubsub, 'unlisten';
  memory_cycle_ok($pubsub, 'cycle ok after unlisten');
  $db->publish_p("rtest:$$:1" => 'nobody is listening to this');

  note 'Making sure the last message is not received';
  Mojo::Promise->timer(0.15)->wait;
  has_messages();
};

subtest 'listen patterns' => sub {
  $pubsub->listen("rtest:$$:*" => \&gather);
  Mojo::Promise->timer(0.1)->wait;

  $pubsub->notify("rtest:$$:4" => 'message four');
  $pubsub->notify("rtest:$$:5" => 'message five');
  wait_for_messages(2);

  has_messages("rtest:$$:5/message five", "rtest:$$:4/message four");
  $pubsub->unlisten("rtest:$$:*");
};

subtest connection => sub {
  my $conn = $pubsub->connection;
  is @{$conn->subscribers('response')}, 1, 'only one message subscriber';

  undef $pubsub;
  delete $redis->{pubsub};
  isnt $redis->db->connection, $conn, 'pubsub connection cannot be re-used';
};

subtest 'json data' => sub {
  $pubsub = $redis->pubsub;
  $pubsub->listen("rtest:$$:1" => \&gather);
  Mojo::Promise->timer(0.1)->wait;

  $pubsub->notify_p("rtest:$$:1" => '{"invalid"');
  $pubsub->json("rtest:$$:1");
  $pubsub->notify("rtest:$$:1" => {some => 'data'});
  $pubsub->notify("rtest:$$:1" => 'just a string');
  wait_for_messages(3);

  has_messages("rtest:$$:1/undef", qq(rtest:$$:1/HASH/{"some":"data"}), "rtest:$$:1/just a string");
};

subtest events => sub {
  is_deeply [sort { $a cmp $b } map { $_->[0] } @events], [qw(psubscribe subscribe subscribe)], 'events';
};

done_testing;

sub gather {
  shift;
  push @messages, join '/', map { !defined($_) ? 'undef' : ref($_) ? (ref($_), encode_json($_)) : $_ } reverse @_;
}

sub has_messages {
  is_deeply [sort @messages], [sort @_], 'has messages' or diag explain \@messages;
  @messages = ();
}

sub wait_for_messages {
  my $n = shift;
  Mojo::IOLoop->one_tick until @messages >= $n;
}
