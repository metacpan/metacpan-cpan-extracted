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

subtest "not locked exit 0" => sub {
    my ($code, $elapsed) = redis_setlock(
        "--redis" => "127.0.0.1:$port",
        $lock_key,
        "perl", "-e", "exit 0",
    );
    ok $code == 0, "got lock and exit $code == 0";
    ok $elapsed < 1, "elapsed $elapsed < 1 sec";
};

subtest "not locked exit non zero" => sub {
    my ($code, $elapsed) = redis_setlock(
        "--redis" => "127.0.0.1:$port",
        $lock_key,
        "perl", "-e", "exit 1",
    );
    ok $code != 0, "got lock and exit $code != 0";
    ok $elapsed < 1, "elapsed $elapsed < 1 sec (= not locked)";
};

if ($ENV{SETLOCK} ) {
    done_testing;
    exit;
}

subtest "set expires and keep lock" => sub {
    my ($code, $elapsed) = redis_setlock(
        "--redis"   => "127.0.0.1:$port",
        "--expires" => 4,
        "--keep",
        $lock_key,
        "perl", "-e", "exit 0",
    );
    is $code => 0, "got lock and exit 0";
    ok $elapsed < 1, "elapsed $elapsed < 1 sec (= not locked)";
};

subtest "wait for lock expired" => sub {
    my ($code, $elapsed) = redis_setlock(
        "--redis"   => "127.0.0.1:$port",
        $lock_key,
        "perl", "-e", "exit 0",
    );
    is $code => 0, "got lock and exit 0";
    ok $elapsed > 3, "elapsed $elapsed > 3 sec (lock expired about 4 sec.)";
    ok $elapsed < 5, "elapsed $elapsed < 5 sec (lock expired about 4 sec.)";
};

subtest "set expires and keep lock" => sub {
    my ($code, $elapsed) = redis_setlock(
        "--redis"   => "127.0.0.1:$port",
        "--expires" => 4,
        "--keep",
        $lock_key,
        "perl", "-e", "exit 0",
    );
    is $code => 0, "got lock and exit 0";
    ok $elapsed < 1, "elapsed $elapsed < 1 sec (= not locked)";
};

subtest "nodelay" => sub {
    my ($code, $elapsed) = redis_setlock(
        "--redis" => "127.0.0.1:$port",
        "-n",
        $lock_key,
        "perl", "-e", "exit 0",
    );
    ok $code != 0, "got lock and exit with $code != 0";
    ok $elapsed < 1, "elapsed $elapsed < 1 sec (= no delay)";
};

subtest "nodelay with exit 0" => sub {
    my ($code, $elapsed) = redis_setlock(
        "--redis" => "127.0.0.1:$port",
        "-n",
        "-x",
        $lock_key,
        "perl", "-e", "exit 0",
    );
    ok $code == 0, "got lock and exit with $code == 0";
    ok $elapsed < 1, "elapsed $elapsed < 1 sec (= no delay)";
};

undef $redis_server; # stop redis-server

subtest "can't connect to redis (no delay exit non zero)" => sub {
    my ($code, $elapsed) = redis_setlock(
        "--redis" => "127.0.0.1:$port",
        "-n",
        $lock_key,
        "perl", "-e", "exit 0",
    );
    ok $code != 0,   "exit with $code != 0";
    ok $elapsed < 1, "elapsed $elapsed < 1";
};

subtest "can't connect to redis (delay 3 sec exit non zero)" => sub {
    my ($code, $elapsed) = redis_setlock(
        "--redis"   => "127.0.0.1:$port",
        "--expires" => 3,
        $lock_key,
        "perl", "-e", "exit 0",
    );
    ok $code != 0,   "exit with $code != 0";
    ok $elapsed > 3, "elapsed $elapsed > 3";
    ok $elapsed < 5, "elapsed $elapsed < 5";
};

done_testing;
