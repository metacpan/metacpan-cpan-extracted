use Mojo::Base -strict;
use Test::More;
use Mojo::Redis;

plan skip_all => 'TEST_ONLINE=redis://localhost' unless $ENV{TEST_ONLINE};

my $redis = Mojo::Redis->new($ENV{TEST_ONLINE});
my $db    = $redis->db;
my $key   = "txn:$0";
my @res;

$db->multi_p->then(sub {
  return Mojo::Promise->all($db->set_p($key => 1011), $db->get_p($key), $db->incr_p($key), $db->incrby_p($key => -10));
})->then(sub {
  push @res, map { $_->[0] } @_;
  return $db->exec_p;
})->then(sub {
  push @res, @{$_[0]};
})->wait;
is_deeply(\@res, [('QUEUED') x 4, 'OK', 1011, 1012, 1002], 'exec_p');

@res = ($db->tap('multi')->tap(get => $key)->tap(incrby => $key => 10)->exec);
is_deeply($res[0], [1002, 1012], 'exec');

@res = ($db->tap('multi')->set($key => 'something else'));
is_deeply(\@res, ['QUEUED'], 'set after multi');
undef $db;
is $redis->db->get($key), 1012, 'rollback when $db goes out of scope';

done_testing;
