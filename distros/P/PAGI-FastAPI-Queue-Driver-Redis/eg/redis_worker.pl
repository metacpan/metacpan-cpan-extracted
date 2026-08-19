#!/usr/bin/env perl

use v5.38;
use PAGI::FastAPI::Queue;
use PAGI::FastAPI::Queue::Driver::Redis;
use Future::AsyncAwait;
use Future::IO;

my $worker_id = $ARGV[0] // $$;

my $queue = PAGI::FastAPI::Queue->new(
    driver  => 'PAGI::FastAPI::Queue::Driver::Redis',
    options => {
        host   => '127.0.0.1',
        port   => 6379,
        prefix => 'myapp:queue:',
    },
);

say "Worker [$worker_id] started. Waiting for jobs...";

while (1) {
    my $job = $queue->pop('default')->get;

    if ($job) {
        my $id   = $job->{job_id} // 'N/A';
        my $data = $job->{data}   // 'N/A';

        say "Worker [$worker_id] START processing job ID: $id ($data)";
        Future::IO->sleep(1)->get;
        say "Worker [$worker_id] FINISHED job ID: $id";
    } else {
        Future::IO->sleep(0.5)->get;
    }
}
