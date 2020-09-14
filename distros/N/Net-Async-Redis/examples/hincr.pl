#!/usr/bin/env perl 
use strict;
use warnings;

use Net::Async::Redis;
use Future::AsyncAwait;
use IO::Async::Loop;

use List::Util qw(min max);

my $loop = IO::Async::Loop->new;
$loop->add(my $redis = Net::Async::Redis->new);

my $shutdown = $loop->new_future;
$loop->watch_signal(
    TERM => sub { $shutdown->done unless $shutdown->is_ready },
    QUIT => sub { $shutdown->done unless $shutdown->is_ready },
);

(async sub {
    await $redis->connect;
    my ($min, $max, $avg, $last);
    my $f = (async sub {
        while(1) {
            await $loop->delay_future(after => 1);
            printf "Ping time - latest %.3fms, min/avg/max %.3fms/%.3fms/%.3fms\n", $last, $min, $avg, $max;
        }
    })->();
    my $count = 0;
    my $sum = 0;
    until($shutdown->is_ready) {
        my $start = Time::HiRes::time();
        await Future->wait_all(
            map { $redis->hincrbyfloat("some_key::" . rand(), rand(), int(100 * rand())) } 1..2000
        );
        my $elapsed = 1000.0 * (Time::HiRes::time() - $start);
        ++$count;
        $sum += $elapsed;
        $min = min($elapsed, $min // ());
        $max = max($elapsed, $max // ());
        $avg = $sum / $count;
        $last = $elapsed;
    }
    $f->cancel;
})->()->get;

