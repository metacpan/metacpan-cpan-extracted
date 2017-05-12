# -*- mode:perl -*-
use strict;
use warnings;
use Test::More;
use Test::SharedFork;
use Redis::Setlock;
use t::Util qw/ redis_server redis_setlock /;
use POSIX ();

my $redis_server = redis_server();
my $port = $redis_server->conf->{port};
my $lock_key = join("-", time, $$, rand());

if (my $pid = fork()) {
    sleep 2;
    my $k = kill POSIX::SIGTERM, $pid;
    ok $k, "killed";
    ok wait, "wait";
}
else {
    my ($code, $elapsed) = redis_setlock(
        "--redis" => "127.0.0.1:$port",
        $lock_key,
        "perl", "-e", "sleep 5",
    );
    is $code & 127 => POSIX::SIGTERM, "got lock and exit 15(SIGTERM)";
    ok $elapsed > 2, "run seconds $elapsed > 2";
    ok $elapsed < 3, "run seconds $elapsed < 3";
    exit;
}

done_testing;
