use Mojo::Base -strict;
use Test::More;
use Mojo::Redis;

plan skip_all => 'TEST_ONLINE=redis://localhost' unless $ENV{TEST_ONLINE};

my $redis      = Mojo::Redis->new($ENV{TEST_ONLINE});
my $cache      = $redis->cache(namespace => $0);
my $n_computed = 0;
my $res;

# Using Protocol::Redis::XS 0.05 does not work
$cache->connection($redis->_dequeue) if $ENV{TEST_XS};

cleanup();

for my $i (1 .. 2) {
  note "run $i";
  $cache->compute_p(
    'some:key',
    60.7,
    sub {
      $n_computed++;
      my $p = Mojo::Promise->new;
      Mojo::IOLoop->timer(0.1 => sub { $p->resolve('some data') });
      return $p;
    }
  )->then(sub { $res = shift })->wait;

  is $res, 'some data', 'computed some:key';

  $cache->compute_p('some:other:key', sub { $n_computed++; +{some => "data"} })->then(sub { $res = shift })->wait;
  is_deeply $res, {some => 'data'}, 'computed some:other:key';

  $cache->memoize_p(main => 'cache_me', [42], 5)->then(sub { $res = shift })->wait;
  is_deeply $res, 42, 'memoize cache_me with 42';

  $cache->memoize_p(main => 'cache_me')->then(sub { $res = shift })->wait;
  is_deeply $res, 'default value', 'memoize cache_me with default';

  $cache->memoize_p(main => 'cache_me', 30)->then(sub { $res = shift })->wait;
  is_deeply $res, 'default value', 'memoize cache_me with default';

  $cache->memoize_p(main => 'cache_me', [{foo => 42}])->then(sub { $res = shift })->wait;
  is_deeply $res, {foo => 42}, 'memoize cache_me with hash';

  $cache->compute_p('some:negative:key', -5.2, sub { $n_computed++; 'too cool' })->then(sub { $res = [@_] })->wait;
  is_deeply $res, ['too cool', $i == 1 ? {computed => 1} : {expired => 0}], 'compute_p with negative expire';
}

is $n_computed, 6, 'compute only called once per key';

note 'refresh';
$cache->refresh(1)->memoize_p(main => 'cache_me', [{foo => 42}])->then(sub { $res = shift })->wait;
is $n_computed, 7, 'compute called after refresh()';

note 'exception';
$cache->compute_p('some:die:key', sub { die 'oops!' })->then(sub { $res = shift })->catch(sub { $res = shift })->wait;
like $res, qr{oops!}, 'failed to cache';

note 'stale cache';
Mojo::Util::monkey_patch('Mojo::Redis::Cache', _time => sub { Time::HiRes::time() + 5.2 });
$cache->refresh(0);
$cache->compute_p('some:negative:key', -5.2, sub { die "yikes!\n" })->then(sub { $res = [@_] })
  ->catch(sub { $res = shift })->wait;
is_deeply $res, ['too cool', {error => "yikes!\n", expired => 1}], 'compute_p expired data and error';

note 'refreshed cache';
$cache->compute_p('some:negative:key', -5.2, sub { $n_computed++; 'cool2' })->then(sub { $res = [@_] })
  ->catch(sub { $res = shift })->wait;
is_deeply $res, ['cool2', {computed => 1, expired => 1}], 'compute_p expired data';

cleanup();
done_testing;

sub cache_me {
  $n_computed++;
  return $_[1] || 'default value';
}

sub cleanup {
  $redis->db->del(
    map {"$0:$_"} 'some:key',
    'some:die:key', 'some:negative:key', 'some:other:key', '@M:main:cache_me:[]', '@M:main:cache_me:[42]',
    '@M:main:cache_me:[{"foo":42}]',
  );
}
