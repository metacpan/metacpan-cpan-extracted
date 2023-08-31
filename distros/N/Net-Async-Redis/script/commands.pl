#!/usr/bin/env perl 
use strict;
use warnings;

use Test::More;
use Test::Deep;
use Path::Tiny;
use experimental qw(for_list);
use JSON::MaybeUTF8 qw(:v2);
use Future::AsyncAwait;
use Net::Async::Redis;
use IO::Async::Loop;
use Log::Any::Adapter qw(Stderr), log_level => 'debug';
use Log::Any qw($log);

my ($server, $port) = @ARGV
    or die 'need a server';
($server, $port) = $server =~ /^(.*):([0-9]+)$/ unless $port;

my $loop = IO::Async::Loop->new;
$loop->add(
    my $redis = Net::Async::Redis->new(
        host => $server,
        port => $port
    )
);
await $redis->connect;

use YAML::XS ();
$log->infof('Connected');
my $def = await $redis->retrieve_full_command_list;
path('share/commands.yaml')->spew_utf8(YAML::XS::Dump($def));
# $log->infof('Commands: %s', format_json_text($def));
for my ($cmd, $keys) (
    [qw(set somekey someval)] => [qw(somekey)],
    [qw(get somekey)] => [qw(somekey)],
    [qw(unlink x y z)] => [qw(x y z)],
    [qw(xreadgroup group somegroup someworker count 50 streams first second third > > >)] => [qw(first second third)],
    [qw(xadd whatever nomkstream * worker 123 id 456)] => [qw(whatever)],
    [qw(hmset somekey x 1 y 2 z 3)] => [qw(somekey)],
    [qw(mget first second third fourth)] => [qw(first second third fourth)],
    [qw(zunion 5 one two three four five weights 1 2 3 4 5 aggregate min withscores)] => [qw(one two three four five)],
) {
    my @keys = $redis->extract_keys_for_command($cmd);
    cmp_deeply(\@keys, bag($keys->@*), 'keys match for ' . join(' ', $cmd->@*))
        or note explain $def->{$cmd->[0]};
}
done_testing;
