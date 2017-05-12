use strict;
use Test::More;

use Redis;
use Resque;
use Test::RedisServer;
use Test::MockTime qw/set_fixed_time restore_time/;
use Time::Strptime qw/strptime/;

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new;
} or plan skip_all => 'redis-server is required to this test';

my $redis = Redis->new($redis_server->connect_info);

my $resque = Resque->new(redis => $redis, plugins => ['Delay']);
isa_ok $resque->plugins->[0], 'Resque::Plugin::Delay';

my ($start_time)  = strptime('%Y-%m-%d %H:%M:%S', '2017-04-01 12:00:00');

fixed_time($start_time - 1, sub {
    $resque->push('test-job' => +{
            class => 'hoge',
            args => ['huga'],
            start_time => $start_time,
        }
    );
    my $job = $resque->pop('test-job');
    is $job, undef, 'The time of work has not arrived';
});

fixed_time($start_time, sub {
    my $job = $resque->pop('test-job');
    isa_ok $job, 'Resque::Job', 'The time of work came';
});

done_testing;

sub fixed_time {
    my ($epoch, $code) = @_;

    set_fixed_time($epoch);
    $code->();
    restore_time();
}

