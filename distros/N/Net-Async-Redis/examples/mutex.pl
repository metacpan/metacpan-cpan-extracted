#!/usr/bin/env perl
use strict;
use warnings;
use feature qw(signatures);

use Net::Async::Redis;
use IO::Async::Loop;

use Future::AsyncAwait;
use Syntax::Keyword::Try;
use Syntax::Keyword::Dynamically;
use Future::Utils qw(fmap_void fmap_concat repeat);

use Log::Any qw($log);
use Log::Any::Adapter qw(Stderr), log_level => 'info';

my $loop = IO::Async::Loop->new;

my %count;
await fmap_void(async sub ($id) {
    dynamically $log->context->{instance} = $id;
    $loop->add(
        my $redis = Net::Async::Redis->new(
            host => $ENV{NET_ASYNC_REDIS_HOST} // 'localhost',
            port => $ENV{NET_ASYNC_REDIS_PORT} // '6379',
            client_side_cache_size => 100,
        )
    );

    await $redis->connected;
    my $removed = $loop->new_future;
    die 'no cc cache?' unless $redis->is_client_side_cache_enabled;
    my $src = $redis->clientside_cache_events
        ->each(sub {
            $log->infof('Key change detected for %s', $_);
            if($_ eq 'task.busy') {
                my $f = $removed;
                $removed = $loop->new_future;
                $f->done
            } else {
                $log->infof('Nothing to do with us');
            }
        });

    my $timeout = $loop->delay_future(after => 5);
    until($timeout->is_ready) {
        await $loop->delay_future(after => 0.005 * rand);
        $log->infof('Try to set key');
        if(my $res = await $redis->set('task.busy' => $id, qw(NX GET PX), 3_000)) {
            $log->infof('We lost - res = %s', $res);
            if(await $redis->get('task.busy')) {
                await $removed;
                $log->infof('Notified removal');
            } else {
                $log->infof('Key disappeared');
            }
        } else {
            $log->infof('We won');
            ++$count{$id};
            await $loop->delay_future(after => 0.003 * rand);
            $log->infof('Release');
            await $redis->del('task.busy');
        }
    }
    return;
}, foreach => [1..10], concurrent => 10);
$log->infof('done');
$log->infof('Stats: %s', \%count);
