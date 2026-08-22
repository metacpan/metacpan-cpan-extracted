#!/usr/bin/env perl

# Start the app:
#
#   pagi-server eg/queue_demo.pl
#
# Submit a job:
#
#   curl -X POST "http://127.0.0.1:5000/tasks?item=report_job_1"
#
# Check queue size:
#
#   curl http://127.0.0.1:5000/tasks/status
#
# Process the next queued task
#
#   curl -X POST http://127.0.0.1:5000/tasks/process

use v5.38;
use PAGI::FastAPI;
use PAGI::FastAPI::Queue;
use Future::AsyncAwait;

my $app = PAGI::FastAPI->new(
    title       => 'PAGI Queue Task Processing Service',
    version     => '1.0.0',
);

my $queue = PAGI::FastAPI::Queue->new( driver => 'Memory' );

$app->post('/tasks',
    summary => 'Enqueue a background task',
    handler => async sub ($c) {
        my $item = $c->query_params->{item} // 'default_item';

        my $job_data = {
            task => 'process_payload',
            data => $item,
        };

        my $job_id = await $queue->push('default', $job_data);
        $job_data->{id} = $job_id;

        return {
            status => 'queued',
            job_id => $job_id,
        };
    }
);

$app->post('/tasks/process',
    summary => 'Process the next queued task',
    handler => async sub ($c) {
        my $job = await $queue->pop('default');

        unless ($job) {
            $c->status(404);
            return { error => 'No tasks in queue' };
        }

        return {
            status => 'completed',
            job_id => $job->{id},
            result => "Processed " . $job->{data},
        };
    }
);

$app->get('/tasks/status',
    summary => 'Get current queue status',
    handler => async sub ($c) {
        my $count = await $queue->size('default');

        return {
            pending_count => $count,
        };
    }
);

$app->to_app;
