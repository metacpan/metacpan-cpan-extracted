use Mojo::Base -strict;
use Test::More;
use Mojo::Redis;

my @events;
my $redis  = Mojo::Redis->new($ENV{TEST_ONLINE} || 'redis://localhost');
my $pubsub = $redis->pubsub;

my $dbsel = $redis->url->path->[0] // '*';
is $pubsub->_keyspace_key, '__keyevent@'.$dbsel.'__:*', 'keyevent default db wildcard';

$redis->url->path->parse('/5');
is $pubsub->_keyspace_key, '__keyevent@5__:*', 'keyevent default wildcard';
is $pubsub->_keyspace_key({type => 'key*'}), '__key*@5__:*', 'keyboth wildcard listen';
is $pubsub->_keyspace_key(foo => undef), '__keyspace@5__:foo', 'keyspace foo';
is $pubsub->_keyspace_key(undef, 'del'), '__keyevent@5__:del', 'keyevent del';
is $pubsub->_keyspace_key('foo', 'rename', {db => 1, key => 'x', op => 'y'}), '__keyspace@1__:foo',
  'keyspace foo and db';
is $pubsub->_keyspace_key({db => 0, key => 'foo', type => 'key*'}), '__key*@0__:foo', 'key* db and type';

my $cb = $pubsub->keyspace_listen(undef, 'del', {db => 1}, sub { });
is ref($cb), 'CODE', 'keyspace_listen returns callback';
is_deeply $pubsub->{chans}{'__keyevent@1__:del'}, [$cb], 'callback is set up';
is $pubsub->keyspace_unlisten(undef, 'del', {db => 1}, $cb), $pubsub, 'keyspace_unlisten with callback';
ok !$pubsub->{chans}{'__keyevent@1__:del'}, 'callback is removed';
$pubsub->{chans}{'__keyevent@1__:del'} = [$cb];
is $pubsub->keyspace_unlisten(undef, 'del', {db => 1}), $pubsub, 'keyspace_unlisten without callback';
ok !$pubsub->{chans}{'__keyevent@1__:del'}, 'callback is removed';

if ($ENV{TEST_KEA} && $ENV{TEST_ONLINE}) {
  my $kea = $redis->db->config(qw(get notify-keyspace-events))->[1];
  diag "config get notify-keyspace-events == $kea";
  $redis->db->config(qw(set notify-keyspace-events KEA));

  $redis->pubsub->keyspace_listen(\&gather);
  $redis->pubsub->keyspace_listen({type => 'keyspace'}, \&gather);
  Mojo::IOLoop->timer(0.15 => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;

  my $key = 'mojo:redis:test:keyspace:listen';
  $redis->db->tap(set => $key => __FILE__)->del($key => __FILE__);
  Mojo::IOLoop->start;
  $redis->db->config(qw(set notify-keyspace-events), $kea);

  ok + (grep { $_->[1] eq 'del' } @events), 'keyspace del event';
  ok + (grep { $_->[1] eq 'set' } @events), 'keyspace set event';
  ok + (grep { $_->[0] =~ /:set$/ } @events), 'keyevent set event';
  ok + (grep { $_->[0] =~ /:del$/ } @events), 'keyevent del event';
}

done_testing;

sub gather {
  push @events, $_[1];
  Mojo::IOLoop->stop if @events >= 4;
}
