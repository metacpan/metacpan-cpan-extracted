#!/usr/bin/env perl 
use strict;
use warnings;

use Net::Async::Redis;
use IO::Async::Loop::Epoll;
use IO::Async::Timer::Periodic;

use Future::Utils qw(fmap_void fmap_concat repeat);

use Log::Any qw($log);
use Log::Any::Adapter qw(Stdout), log_level => 'info';

use Future::Utils qw(fmap0);

my $loop = IO::Async::Loop::Epoll->new;

my $connection_count = 4;
my @conn = map {;
    $loop->add(
        my $redis = Net::Async::Redis->new
    );
    $redis;
} 0..$connection_count;

my $message_count = 0;
Future->wait_all(
    map $_->connect, @conn
)->then(sub {
    $log->debug("All instances connected, starting test");
    my ($primary) = @conn;
    $log->infof('Clearing out old streams');
    Future->wait_all(
        $primary->xgroup(
            DESTROY => 'example_stream',
            'primary_group'
        )->on_ready(sub { $log->debugf('ready primary_group') }),
        $primary->xgroup(
            DESTROY => 'example_stream',
            'secondary_group',
        )->on_ready(sub { $log->debugf('ready secondary_group') }),
        $primary->del(
            'example_stream',
        )->on_ready(sub { $log->debugf('ready example_stream') }),
    )->then(sub {
        $log->infof('About to add some data to streams');
        my $start = Time::HiRes::time;
        (
            repeat {
                $loop->delay_future(after => 0.005 * rand)
                    ->then(sub {
                        $primary->xadd(
                            example_stream => '*',
                            id => int(1_000_000 * rand)
                        )->retain;
                    })
            } while => sub { 1 }
        )->retain;
        $loop->add(
            IO::Async::Timer::Periodic->new(
                interval => 1,
                on_tick => sub {
                    my $elapsed = Time::HiRes::time - $start;
                    $log->infof("%d messages after %d seconds, %.2f/sec",
                        $message_count, $elapsed, $message_count / ($elapsed || 0)
                    );
                }
            )->start
        );
        (fmap_void {
            my ($idx) = @_;
            $primary->xadd(
                example_stream => '*',
                id => $_
            )
        } foreach => [qw(a b c x y z)])
    })->then(sub {
        $log->infof('Set up 2 consumer groups');
        Future->needs_all(
            $primary->xgroup(
                CREATE => 'example_stream',
                primary_group => '0'
            ),
            $primary->xgroup(
                CREATE => 'example_stream',
                secondary_group => '0'
            ),
        )
    })->then(sub {
        $log->infof('Start workers');
        fmap_concat {
            my ($id) = @_;
            my ($worker_id) = 'worker_' . $id;
            my ($redis) = $conn[$id];
            repeat {
                $redis->xreadgroup(
                    BLOCK       => 2000,
                    GROUP       => 'primary_group',
                    $worker_id,
                    COUNT       => 1,
                    STREAMS     => 'example_stream',
                    '>'
                )->then(sub {
                    my ($item) = @_;
                    $log->debugf('readgroup returns %s', $item);
                    return Future->done unless $item;
                    my ($stream, $items) = map @$_, @$item;
                    my ($id, $content) = map @$_, @$items;
                    my (%data) = @{$content || []};
                    $log->debugf('Data was %s for ID %s and data was %s', $stream, $id, \%data);
                    ++$message_count;
                    $redis->xack(
                        $stream => 'primary_group',
                        $id
                    )
                })->on_fail(sub { $log->errorf('fialed future - %s', [ @_ ]) })
            } while => sub { 1 }
        } foreach    => [1..$connection_count],
          concurrent => $connection_count
    })
})->get;
# DB::disable_profile();

