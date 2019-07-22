#!/usr/bin/env perl 
use strict;
use warnings;

=head1 NAME

lrange.pl

=head1 DESCRIPTION

Combined LRANGE/LTRIM.

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

my $loop = IO::Async::Loop::Epoll->new;

$loop->add(
    my $redis = Net::Async::Redis->new
);
$loop->add(
    my $sub = Net::Async::Redis->new
);

use constant REDIS_KEY => 'example::lrange';

(async sub {
    await $redis->connected;
    await $redis->del(REDIS_KEY);
    await $redis->rpush(REDIS_KEY, 'a'..'z');
    my $el = await $redis->lrange(REDIS_KEY, 0, 9);
    $log->infof('Elements are %s', $el);
    await $redis->ltrim(REDIS_KEY, 10, -1);
    my $remaining = await $redis->lrange(REDIS_KEY, 0, -1);
    $log->infof('Remaining %s', $remaining);
})->()->get;


