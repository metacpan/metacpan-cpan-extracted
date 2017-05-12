use Test::More;
use strict;

use Net::Ostrich;

plan skip_all => 'set NET_OSTRICH_HOST' unless $ENV{NET_OSTRICH_HOST};

die unless $ENV{NET_OSTRICH_PORT};

my $no = Net::Ostrich->new(host => $ENV{NET_OSTRICH_HOST}, port => $ENV{NET_OSTRICH_PORT});

my $stats = $no->stats;
ok(exists($stats->{gauges}->{jvm_thread_count}), 'got a gauge from stats');

my $ping = $no->ping;
cmp_ok($ping->{response}, 'eq', 'pong', 'ping');

my $resp = $no->reload;
cmp_ok($resp->{response}, 'eq', 'ok', 'reload');

my $gc = $no->gc;
cmp_ok($gc->{response}, 'eq', 'ok', 'gc');

my $threads = $no->threads;
ok(exists($threads->{threads}), 'threads');

# Not testing these, since they shut shit down.

# my $quiesce = $no->quiesce;
# cmp_ok($quiesce->{response}, 'eq', 'ok', 'quiesce');
# 
# my $shut = $no->shutdown;
# cmp_ok($shut->{response}, 'eq', 'ok', 'shutdown');

done_testing;