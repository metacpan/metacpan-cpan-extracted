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
my $port         = $redis_server->conf->{port};
my $lock_key     = join("-", time, $$, rand());
my @pid;
for my $child (1, 2) {
    if (my $pid = fork()) {
        push @pid, $pid;
    }
    elsif ($child == 1) {
        child_1();
        exit;
    }
    elsif ($child == 2) {
        child_2();
        exit;
    }
}
wait for @pid;
done_testing;

sub child_1 {
    my ($code, $elapsed) = redis_setlock(
        "--redis" => "127.0.0.1:$port",
        "-n",
        $lock_key,
        "perl", "-e", 'sleep 2',
    );
    is $code => 0, "got lock and exit 0";
    ok $elapsed > 2, "elapsed seconds $elapsed > 2";
    ok $elapsed < 3, "elapsed seconds $elapsed < 3";
}

sub child_2 {
    sleep 1;
    my ($code, $elapsed) = redis_setlock(
        "--redis" => "127.0.0.1:$port",
        "-n",
        $lock_key,
        "perl", "-e", "exit 0",
    );
    ok $code != 0, "can't get lock and exit $code != 0";
    ok $elapsed < 1, "elapsed $elapsed < 1 (no delay)";

    ($code, $elapsed) = redis_setlock(
        "--redis" => "127.0.0.1:$port",
        "-n",
        "-x",
        $lock_key,
        "perl", "-e", "exit 0",
    );
    ok $code == 0, "can't get lock and exit $code == 0";
    ok $elapsed < 1, "elapsed $elapsed < 1 (no delay)";
}
