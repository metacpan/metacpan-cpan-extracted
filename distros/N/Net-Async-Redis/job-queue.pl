#!/usr/bin/env perl
use strict;
use warnings;

use Net::Async::Redis;
use IO::Async::Loop::Epoll;
use IO::Async::Timer::Periodic;

use Log::Any qw($log);
use Log::Any::Adapter qw(Stdout), log_level => 'debug';

use Future::Utils qw(fmap0);

my $loop = IO::Async::Loop::Epoll->new;

my %conn;
for my $idx (1..1000) {
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
            (fmap0 {
                $loop->delay_future(
                    after => 0.025 * rand
                )->then(sub {
                    $log->debugf("Incr $key");
                    $redis->incr($key)->then(sub {
                        my ($count) = @_;
                        ++$incr_count;
                        $log->debugf("%s => %d", $key => $count);
                        $count == 1
                        ? $redis->expire($key => 5)
                        : Future->done
                    }, sub { $log->errorf("Error! %s", @_) })
                }, sub { warn "here? @_" })
            } foreach => [1..10000], concurrent => 10)
        } keys %conn
    )
})->get;
