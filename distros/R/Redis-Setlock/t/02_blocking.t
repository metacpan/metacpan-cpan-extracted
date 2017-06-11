# -*- mode:perl -*-
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../";
use Test::More;
use Test::SharedFork;
use Redis::Setlock;
use t::Util qw/ redis_server redis_setlock /;

my $redis_server = redis_server();
my $port = $redis_server->conf->{port};
my $lock_key = join("-", time, $$, rand());

if (my $pid = fork()) {
    my ($code, $elapsed) = redis_setlock(
        "--redis" => "127.0.0.1:$port",
        $lock_key,
        "perl", "-e", "sleep 2",
    );
    is $code => 0, "got lock and exit 0";
    ok $elapsed > 2, "elapsed seconds $elapsed > 2";
    ok $elapsed < 3, "elapsed seconds $elapsed < 3";
    wait;
}
else {
    sleep 1;
    my ($code, $elapsed) = redis_setlock(
        "--redis" => "127.0.0.1:$port",
        $lock_key,
        "perl", "-e", "exit 0",
    );
    is $code => 0, "got lock and exit 0";
    ok $elapsed > 1, "lock wait seconds $elapsed > 1";
    ok $elapsed < 3, "lock wait seconds $elapsed < 3";
    exit;
}

done_testing;
