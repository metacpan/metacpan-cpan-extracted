#!/usr/bin/env perl 
use strict;
use warnings;

=head1 NAME

moving-sum.pl

=head1 DESCRIPTION

Provides a simple example for managing "moving-sum" calculations with Redis:

=over 4

=item * total value tracked in one key

=item * sorted sets used to record elements

=item * total is incremented as new values are added

=item * as old values drop out of the desired window, the total is decremented accordingly

=back

The tracked total uses L<Net::Async::Redis::Commands/incrbyfloat> to provide an atomic update
when the new values are added and removed. This can be tracked using keyspace notifications,
or simply polled if the update interval is low enough.

=cut

use Future::AsyncAwait 0.28;
use Syntax::Keyword::Try 0.07;
use Net::Async::Redis;
use IO::Async::Loop::Epoll;
use IO::Async::Timer::Periodic;

use Log::Any qw($log);
use Log::Any::Adapter qw(Stdout), log_level => 'info';

use POSIX qw(floor);
use List::Util qw(sum0);
use Future::Utils qw(fmap0);

$SIG{PIPE} = 'ignore';
my $loop = IO::Async::Loop::Epoll->new;

$loop->add(
    my $redis = Net::Async::Redis->new
);
$loop->add(
    my $sub = Net::Async::Redis->new
);

use constant REDIS_KEY_PREFIX => 'example::moving_sum::';

(async sub {
    await $redis->connected;
    my $id = 0;
    my $total = 0;
    my $add = async sub {
        my ($item) = @_;
        my $time = Time::HiRes::time;
        my $k = REDIS_KEY_PREFIX . 'elements';
        my $score = floor($time * 100);

        # First we add the new item and update our local score tracking
        await $redis->zadd($k, $score => join ':', $id++, $item);

        # Now we find any older items...
        my $target = $score - 500;
        my @el = (await $redis->zrangebyscore($k => 0, $target))->@*;
        $log->debugf('Have elements: %s', \@el);
        my $diff = $item - sum0 map { /:([0-9]+)$/ } @el;
        $total += $diff;
        await $redis->incrbyfloat(REDIS_KEY_PREFIX . 'current', $diff);
        # ... and clear those out
        await $redis->zremrangebyscore($k => 0, $target);
        my @remaining = (await $redis->zrange($k => 0, -1))->@*;
        $log->debugf('Remaining: %s', \@remaining);
        my $expected = sum0 map { /:([0-9]+)$/ } @remaining;
        $log->infof('Resulting score was %d and we expected %d', $total, $expected);
        $log->errorf('Score mismatch - somehow our internal tracking does not match what was in Redis, difference is %s', $expected - $total) unless $expected == $total;
    };
    my $f = (async sub {
        my $k = REDIS_KEY_PREFIX . 'elements';
        await $redis->del(map { REDIS_KEY_PREFIX . $_ } qw(elements current));
        while(1) {
            await $loop->delay_future(after => 0.002 + rand(0.11));
            await $add->(int rand(100));
        }
    })->();
    (async sub {
        $log->infof('Set up current update notifications');
        await $sub->watch_keyspace(REDIS_KEY_PREFIX . 'current', async sub {
            my ($op, $k) = @_;
            my $v = await $redis->get($k);
            $log->infof('Notified current update: %s = %s', $k, $v);
        });
    })->()->retain;
    await $f;
})->()->get;

