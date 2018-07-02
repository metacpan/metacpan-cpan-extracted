use Mojo::Base -strict;
use Test::More;
use Mojo::Redis;

plan skip_all => 'TEST_ONLINE=redis://localhost' unless $ENV{TEST_ONLINE};

my $redis = Mojo::Redis->new($ENV{TEST_ONLINE});
my $cache = $redis->cache(namespace => $0);
my $n     = 0;
my $res;

cleanup();

for (1 .. 2) {
  $cache->compute_p(
    'some:key',
    60.7,
    sub {
      $n++;
      my $p = Mojo::Promise->new;
      Mojo::IOLoop->timer(0.1 => sub { $p->resolve('some data') });
      return $p;
    }
  )->then(sub { $res = shift })->wait;

  is $res, 'some data', 'computed some:key';

  $cache->compute_p(
    'some:other:key',
    sub {
      $n++;
      return +{some => "data"};
    }
  )->then(sub { $res = shift })->wait;

  is_deeply $res, {some => 'data'}, 'computed some:other:key';

  $cache->memoize_p(main => 'cache_me', [42], 5)->then(sub { $res = shift })->wait;
  is_deeply $res, 42, 'memoize cache_me with 42';

  $cache->memoize_p(main => 'cache_me')->then(sub { $res = shift })->wait;
  is_deeply $res, 'default value', 'memoize cache_me with default';

  $cache->memoize_p(main => 'cache_me', 30)->then(sub { $res = shift })->wait;
  is_deeply $res, 'default value', 'memoize cache_me with default';

  $cache->memoize_p(main => 'cache_me', [{foo => 42}])->then(sub { $res = shift })->wait;
  is_deeply $res, {foo => 42}, 'memoize cache_me with hash';
}

is $n, 5, 'compute only called once per key';

$cache->refresh(1)->memoize_p(main => 'cache_me', [{foo => 42}])->then(sub { $res = shift })->wait;
is $n, 6, 'compute called after refresh()';

$cache->compute_p('some:die:key', sub { die 'oops!' })->catch(sub { $res = shift })->then(sub { $res = shift })->wait;
like $res, qr{oops!}, 'failed to cache';

cleanup();
done_testing;

sub cache_me {
  $n++;
  return $_[1] || 'default value';
}

sub cleanup {
  $redis->db->del(
    map {"$0:$_"} 'some:key',
    'some:die:key', 'some:other:key', '@M:main:cache_me:[]', '@M:main:cache_me:[42]', '@M:main:cache_me:[{"foo":42}]',
  );
}
