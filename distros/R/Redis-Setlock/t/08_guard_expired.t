# -*- mode:perl -*-
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::More;
use Test::SharedFork;
use Redis::Setlock;
use Time::HiRes qw/ gettimeofday tv_interval /;
use t::Util qw/ redis_server redis_setlock /;
use Capture::Tiny ':all';

my $lock_key     = join("-", time, $$, rand());
my $redis_server = redis_server();
my $port         = $redis_server->conf->{port};

my $redis = Redis->new( server => "127.0.0.1:$port" );
ok $redis;

subtest "expired" => sub {
    my $g = Redis::Setlock->lock_guard( $redis, $lock_key, 2 );
    ok $g, "got lock";
    sleep 3;
    my $stderr = capture_stderr { undef $g; };
    like $stderr, qr/already expired/;
};

subtest "warn" => sub {
    local $Redis::Setlock::WARN_LOCK_TIME_THRESHOLD = 1;
    my $g = Redis::Setlock->lock_guard( $redis, $lock_key, 5 );
    ok $g, "got lock";
    sleep 2;
    my $stderr = capture_stderr { undef $g; };
    unlike $stderr, qr/already expired/;
    like $stderr, qr/elasped \d+\.\d+ sec/;
};

subtest "ok" => sub {
    my $g = Redis::Setlock->lock_guard( $redis, $lock_key, 5 );
    ok $g, "got lock";
    sleep 2;
    my $stderr = capture_stderr { undef $g; };
    is $stderr, "";
};

done_testing;
