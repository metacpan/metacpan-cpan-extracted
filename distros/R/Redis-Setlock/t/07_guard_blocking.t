# -*- mode:perl -*-
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::More;
use Test::SharedFork;
use Redis::Setlock;
use Time::HiRes qw/ gettimeofday tv_interval sleep /;
use t::Util qw/ redis_server redis_setlock /;

my $lock_key     = join("-", time, $$, rand());
my $redis_server = redis_server();
my $port         = $redis_server->conf->{port};

if (my $pid = fork()) {
    my $redis = Redis->new( server => "127.0.0.1:$port" );
    ok $redis;
    my $g = Redis::Setlock->lock_guard( $redis, $lock_key, 60, 1);
    ok $g, "got lock parent";
    sleep 3;
    undef $g;
    wait;
}
else {
    my $redis = Redis->new( server => "127.0.0.1:$port" );
    ok $redis;
    sleep 0.2;
    my $t0 = [gettimeofday];
    my $g = Redis::Setlock->lock_guard( $redis, $lock_key, 60, 1);
    my $elapsed = tv_interval $t0;
    ok $g, "got lock child";
    ok $elapsed > 2, "got lock after at leaset 3 sec $elapsed";
    ok $elapsed < 4;
    exit;
}

done_testing;
