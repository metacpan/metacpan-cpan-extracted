#!/usr/bin/env perl 
use strict;
use warnings;

use Future::AsyncAwait 0.18;
use Syntax::Keyword::Try 0.07;
use Net::Async::Redis;
use IO::Async::Loop::Epoll;
use IO::Async::Timer::Periodic;

use Log::Any qw($log);
use Log::Any::Adapter qw(Stdout), log_level => 'info';

use Future::Utils qw(fmap0);

$SIG{PIPE} = 'ignore';
my $loop = IO::Async::Loop::Epoll->new;

my %conn;
for my $idx (1..4) {
    $loop->add(
        my $redis = Net::Async::Redis->new
    );
    $conn{$redis} = $redis;
}

my $incr_count = 0;
my $start = Time::HiRes::time;
$loop->add(
    IO::Async::Timer::Periodic->new(
        interval => 2,
        on_tick => sub {
            my $elapsed = Time::HiRes::time - $start;
            $log->infof("%d INCR calls after %d seconds, %.2f/sec",
                $incr_count, $elapsed, $incr_count / ($elapsed || 0)
            );
        }
    )->start
);
Future->wait_all(
    map $_->connect, values %conn
)->then(sub {
    $log->debug("All instances connected, starting test");
    Future->wait_all(
        map {
            my $key = "ratelimit." . $_;
            my $redis = $conn{$_};
            fmap0(async sub {
                await $loop->delay_future(
                    after => 0.001 * rand
                );
                my $count = await $redis->incr($key);
                ++$incr_count;
                $count == 1
                ? await $redis->expire($key => 5)
                : ()
            }, foreach => [1..100000], concurrent => 10)->on_fail(sub { warn "failed for $key - @_" })
        } keys %conn
    )
})->get;
