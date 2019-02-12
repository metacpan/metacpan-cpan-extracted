use strict;
use utf8;
use warnings;

use Test::More;

{
    package MyCache;
    use Moo;
    with 'Role::Cache::LRU';
}

my ($got, $cacher, $key, $value) = ('', '', 'foo', {a => 1, b => 2, c => 3});

$cacher = MyCache->new;
is($cacher->does('Role::Cache::LRU'), 1, 'expect role implemented');

$got = $cacher->get_cache($key);
is($got, undef, 'expect no cached item found');

$cacher->set_cache($key, $value);
$got = $cacher->get_cache($key);
is_deeply($got, $value, 'expect cached item found');

$got = $cacher->get_cache_size();
is($got, 1024, 'expect default cache size matched');

$cacher->set_cache_size(10);
$got = $cacher->get_cache_size();
is($got, 10, 'expect default new cache size matched');

done_testing;
