#!/usr/bin/env perl

# Prereq for this demo:
#   PAGI::FastAPI v1.1.0
#   PAGI::FastAPI::Queue::Driver::Redis v0.0.1
#   IO::Async v0.805
#
# You need Redis server running locally with default settings
#
# Terminal 1:
# -----------
# Now run the app
#
#   $ pagi-server redis_queue_demo.pl
#
# Terminal 2:
# -----------
# In another terminal, submit 10 messages:
#
#   $ for i in {1..10}; \
#     do \
#     curl -s -X POST "http://127.0.0.1:5000/tasks?item=job_$i" > /dev/null; \
#     done
#
# Check the status:
#
#   $ curl http://127.0.0.1:5000/tasks/status
#   {"pending_count":10}
#
# Terminal 3:
# -----------
# Start worker "A"
#
#   $ perl redis_worker.pl "A"
#
# Terminal 4:
# -----------
# Start worker "B"
#
#   $ perl redis_worker.pl "B"

use v5.38;
use PAGI::FastAPI;
use PAGI::FastAPI::Queue;
use Future::AsyncAwait;

my $app = PAGI::FastAPI->new(
    title   => 'PAGI Redis Queue Demo',
    version => '1.1.0',
);

my $queue = PAGI::FastAPI::Queue->new(
    driver  => 'PAGI::FastAPI::Queue::Driver::Redis',
    options => {
        host   => '127.0.0.1',
        port   => 6379,
        prefix => 'myapp:queue:',
    },
);

my $job_sequence = 0;

$app->post('/tasks',
    summary => 'Enqueue a task to Redis',
    handler => async sub ($c) {
        my $item   = $c->query_params->{item} // 'default_item';
        my $job_id = "job_" . ++$job_sequence . "_" . time();

        await $queue->push('default', {
            job_id => $job_id,
            task   => 'process_payload',
            data   => $item,
        });

        return {
            status => 'queued',
            job_id => $job_id,
            item   => $item,
        };
    }
);

$app->post('/tasks/process',
    summary => 'Process next task from Redis',
    handler => async sub ($c) {
        my $job = await $queue->pop('default');

        unless ($job) {
            $c->status(404);
            return { error => 'No tasks in Redis queue' };
        }

        return {
            status => 'completed',
            job_id => $job->{job_id},
            result => "Processed " . $job->{data},
        };
    }
);

$app->get('/tasks/status',
    summary => 'Get Redis queue status',
    handler => async sub ($c) {
        my $count = await $queue->size('default');

        return {
            pending_count => $count,
        };
    }
);

$app->to_app;
