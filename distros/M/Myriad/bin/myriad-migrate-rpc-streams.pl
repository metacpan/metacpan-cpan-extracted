#!/usr/bin/env perl

# Basic usage: myriad-migrate-rpc-streams.pl --uri <redis_uri> --service <service to migrate>
# This script will move messages from the old single rpc stream into multiple streams
# it won't delete the original stream.

use strict;
use warnings;

use Getopt::Long;

use IO::Async::Loop;
use Future::AsyncAwait;

use Net::Async::Redis;
use Net::Async::Redis::Cluster;

use URI;
use Syntax::Keyword::Try;
use Log::Any qw($log);
use Log::Any::Adapter qw(Stderr), log_level => 'info';

my $uri;
my $is_cluster = 0;
my $service_name;

GetOptions(
    'uri=s'          => \$uri,
    'service=s'      => \$service_name,
    'cluster'        => \$is_cluster,
) or die "usage $0 --uri <redis_uri> --service <service_name> [--cluster]";

$uri = URI->new($uri);
$service_name =~ s/::/./;
$service_name = lc($service_name);

my $loop = IO::Async::Loop->new();

my $redis;

if ($is_cluster) {
    $loop->add(
        $redis = Net::Async::Redis::Cluster->new
    );
    await $redis->bootstrap(
        host => $uri->host,
        port => $uri->port,
    );
} else {
    $loop->add(
        $redis = Net::Async::Redis->new(uri => $uri)
    );
}

my $old_rpc_stream = "myriad.service.$service_name/rpc";
my $new_rpc_stream_prefix = "myriad.service.$service_name.rpc/";

unless ( await $redis->exists($old_rpc_stream) ) {
    $log->fatalf('Cannot find old rpc stream for service %s', $service_name);
    exit 1;
}

try {
    await $redis->xgroup('CREATE', $old_rpc_stream, 'rpc_migration', 0);
} catch ($e) {
    if ($e =~ /BUSYGROUP/) {
        $log->fatalf('Got a busygroup for stream %s are you running another migration?', $old_rpc_stream);
    } else {
        $log->fatalf('Failed to create group for stream %s - %s', $old_rpc_stream, $e);
    }
    exit 1;
}

try {
    while (my ($batch) = await $redis->xreadgroup(
                                            GROUP => 'rpc_migration', 'migrator',
                                            COUNT => 50,
                                            STREAMS => ($old_rpc_stream, '>'),
    )) {
        last unless $batch->@*;
        my ($stream, $messages) = $batch->[0]->@*;
        for my $message ($messages->@*) {
            my ($id, $info) = $message->@*;
            my %args = $info->@*;
            my $stream = $new_rpc_stream_prefix . $args{rpc};

            await $redis->xadd(
                $stream => '*',
                %args
            );
        }
    }
} catch ($e) {
    $log->errorf('Error while migrating streams - %s', $e);
}

await $redis->xgroup('destroy', $old_rpc_stream, 'rpc_migration');
