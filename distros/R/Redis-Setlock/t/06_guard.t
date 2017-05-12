# -*- mode:perl -*-
use strict;
use Test::More;
use Test::SharedFork;
use Redis::Setlock;
use Time::HiRes qw/ gettimeofday tv_interval /;
use t::Util qw/ redis_server redis_setlock /;

my $lock_key     = join("-", time, $$, rand());
my $redis_server = redis_server();
my $port         = $redis_server->conf->{port};

if (my $pid = fork()) {
    my $redis = Redis->new( server => "127.0.0.1:$port" );
    ok $redis;
    my $g = Redis::Setlock->lock_guard( $redis, $lock_key, 60 );
    ok $g, "got lock parent";
    sleep 3;
    undef $g;
    wait;
}
else {
    my $redis = Redis->new( server => "127.0.0.1:$port" );
    ok $redis;
    sleep 1;
    my $g = Redis::Setlock->lock_guard( $redis, $lock_key, 60 );
    ok !$g, "can't lock";
    sleep 3;

    $g = Redis::Setlock->lock_guard( $redis, $lock_key, 60 );
    ok $g, "got lock child";
    exit;
}

done_testing;
