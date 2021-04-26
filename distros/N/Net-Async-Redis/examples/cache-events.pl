#!/usr/bin/env perl
use strict;
use warnings;

use Net::Async::Redis;
use IO::Async::Loop;

use Future::AsyncAwait;
use Syntax::Keyword::Try;
use Future::Utils qw(fmap_void fmap_concat repeat);

use Log::Any qw($log);
use Log::Any::Adapter qw(Stdout), log_level => 'info';

my $loop = IO::Async::Loop->new;

$loop->add(
    my $redis = Net::Async::Redis->new(
        client_side_cache_size => 100,
    )
);

await $redis->connected;
$redis->clientside_cache_events
    ->each(sub {
        $log->infof('Key change detected for %s', $_)
    });
$log->infof('Set key');
await $redis->set('clientside.cached' => 1);
$log->infof('Get key');
await $redis->get('clientside.cached');
$log->infof('Apply more changes');
await $redis->set('clientside.cached' => 2);
await $redis->llen('clientside.cached.lpush');
await $redis->lpush('clientside.cached.lpush' => 1,2,3);
await $redis->hgetall('clientside.cached.hset');
await $redis->hset('clientside.cached.hset' => abc => 123);
await $redis->hset('clientside.cached.hset' => def => 123);
await $redis->hset('clientside.cached.hset' => ghi => 123);
$log->infof('Start loop');
$loop->run;

