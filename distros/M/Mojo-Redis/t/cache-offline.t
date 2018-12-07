BEGIN { $ENV{MOJO_REDIS_CACHE_OFFLINE} = 1 }
use Mojo::Base -strict;
use Test::More;
use Mojo::Redis;

my $redis = Mojo::Redis->new;
my $cache = $redis->cache(namespace => $0);
my $n     = 0;
my $res;

for (1 .. 2) {
  $cache->memoize_p(main => 'cache_me', [{foo => 42}])->then(sub { $res = shift })->wait;
  is_deeply $res, {foo => 42}, 'memoize cache_me with hash';
}

is $n, 1, 'compute only called once per key';

$cache->refresh(1)->memoize_p(main => 'cache_me', [{foo => 42}])->then(sub { $res = shift })->wait;
is $n, 2, 'compute called after refresh()';

$cache->compute_p('some:die:key', sub { die 'oops!' })->catch(sub { $res = shift })->then(sub { $res = shift })->wait;
like $res, qr{oops!}, 'failed to cache';

{
  no warnings 'redefine';
  local *Mojo::Redis::Cache::_time = sub { time + 601 };
  $cache->refresh(0)->memoize_p(main => 'cache_me', [{foo => 42}])->then(sub { $res = shift })->wait;
  is $n, 3, 'compute called after expired';
}

done_testing;

sub cache_me {
  $n++;
  return $_[1] || 'default value';
}
