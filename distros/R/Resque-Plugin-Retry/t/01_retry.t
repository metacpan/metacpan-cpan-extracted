use strict;
use Test::More;
use Test::Exception;

use Redis;
use Resque;
use Test::RedisServer;

my $redis_server;
eval {
    $redis_server = Test::RedisServer->new;
} or plan skip_all => 'redis-server is required to this test';

my $redis = Redis->new($redis_server->connect_info);

my $resque = Resque->new(redis => $redis, plugins => ['Retry']);
isa_ok $resque->plugins->[0], 'Resque::Plugin::Retry';

subtest 'can retry' => sub {
    my $max_retry = 3;
    $resque->push('test-job' => +{
            class => 'Test::Hoge',
            args => ['huga'],
            max_retry => $max_retry,
        }
    );

    my $job = $resque->pop('test-job');

    for my $retry_count (0..($max_retry - 1)) {
        is $job->retry_count, $retry_count;
        $job->perform;
        $job = $resque->pop('test-job');
    }

    is $job->retry_count, $max_retry;
    dies_ok { $job->perform };
};

subtest 'default max_retry' => sub {
    $resque->push('test-job-default' => +{
            class => 'Test::Hoge',
            args => ['hugaaaa'],
        }
    );

    my $job = $resque->pop('test-job-default');
    is $job->retry_count, 0;
    dies_ok { $job->perform };
};

done_testing;

package Test::Hoge;

sub perform {
    my ($job,) = @_;

    die 'job fail';
}

1;

