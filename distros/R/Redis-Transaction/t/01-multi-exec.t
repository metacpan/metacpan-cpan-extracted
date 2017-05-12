use strict;
use warnings;
use Test::More;
use Test::RedisServer;
use Redis::Transaction qw/multi_exec/;
use Time::HiRes qw/time sleep/;

my $redis_backend = $ENV{REDIS_BACKEND} || 'Redis';
eval "use $redis_backend";

my $redis_server = eval { Test::RedisServer->new } or plan skip_all => 'redis-server is required in PATH to run this test';
my $redis = $redis_backend->new( $redis_server->connect_info );

my $start = time;
my $pid = fork;
BAIL_OUT("Cannot fork: $!") unless defined $pid;
if ($pid == 0) {
    # child process
    while (time - $start < 3) {
        multi_exec $redis, 2, sub {
            my $r = shift;
            $r->incr('foo', sub {});
            $r->incr('bar', sub {});
        };
    }
    exit;
}

my $count;
my $err_count = 0;
while (time - $start < 3) {
    my ($foo, $bar) = multi_exec $redis, 2, sub {
        my $r = shift;
        $r->get('foo');
        $r->get('bar');
    };
    $count++;
    $err_count++ if ($foo || 0) != ($bar || 0);
}
is $err_count, 0, 'the value of `foo` always equals the value of `bar`';

my $ret = multi_exec $redis, 2, sub {
    my $r = shift;
    is $r->get('foo'), 'QUEUED', 'commands are QUEUED in the transaction';
};
note sprintf "incremented %d times, and checked values %d times", $ret->[0], $count;

waitpid $pid, 0;

done_testing;
