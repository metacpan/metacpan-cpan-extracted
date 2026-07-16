use v5.40;
use experimental 'signatures';
use Future::AsyncAwait;
use Future::IO;
use PAGI::Nano;

# Ports PAGI's 11-job-runner to PAGI::Nano.
# An async job queue: a REST API to submit and inspect jobs, a background worker
# (rooted in the lifespan) that advances job progress, an SSE stream of a single
# job's progress, and a WebSocket feed of overall queue stats. Job state lives in
# the app-lifetime shared state.
#
#     pagi-server app.pl
#     curl -X POST -H 'content-type: application/json' -d '{"label":"resize"}' \
#          http://127.0.0.1:5000/api/jobs
#     curl -N http://127.0.0.1:5000/api/jobs/1/progress

sub job_view ($job) {
    return { id => $job->{id}, label => $job->{label}, status => $job->{status},
             progress => $job->{progress} };
}

my $app = app {
    startup async sub ($state) {
        $state->{jobs}    = {};   # id => job
        $state->{next_id} = 1;
        # Background worker: advance the first running/queued job each tick.
        $state->{worker} = (async sub {
            while (1) {
                await Future::IO->sleep(1);
                for my $job (sort { $a->{id} <=> $b->{id} } values %{ $state->{jobs} }) {
                    next if $job->{status} eq 'done';
                    $job->{status} = 'running';
                    $job->{progress} += 25;
                    $job->{status} = 'done' if $job->{progress} >= 100;
                    last;   # one unit of work per tick
                }
            }
        })->();
    };

    # --- REST API ---
    post '/api/jobs' => async sub ($c) {
        my $attrs = await $c->params->permitted('label');
        my $id = $c->state->{next_id}++;
        my $job = { id => $id, label => $attrs->{label} // "job-$id",
                    status => 'queued', progress => 0 };
        $c->state->{jobs}{$id} = $job;
        $c->json(job_view($job), status => 201);
    };

    get '/api/jobs' => sub ($c) {
        [ map { job_view($_) }
          sort { $a->{id} <=> $b->{id} } values %{ $c->state->{jobs} } ];
    };

    get '/api/jobs/:id' => sub ($c, $id) {
        my $job = $c->state->{jobs}{$id}
            or return $c->json({ error => 'no such job' }, status => 404);
        job_view($job);
    };

    # --- SSE: stream one job's progress until it finishes ---
    sse '/api/jobs/:id/progress' => async sub ($c, $id) {
        my $s = $c->sse;
        my $job = $c->state->{jobs}{$id};
        unless ($job) { await $s->send_event(event => 'error', data => 'no such job'); await $s->close; return }
        while ($job->{status} ne 'done') {
            await $s->send_event(event => 'progress', data => $job->{progress});
            await Future::IO->sleep(1);
        }
        await $s->send_event(event => 'done', data => 100);
        await $s->close;
    };

    # --- WebSocket: push overall queue stats ---
    websocket '/ws/queue' => async sub ($c) {
        my $ws = $c->websocket;
        await $ws->accept;
        while ($ws->is_connected) {
            my @jobs = values %{ $c->state->{jobs} };
            await $ws->send_json_if_connected({
                total => scalar(@jobs),
                done  => scalar(grep { $_->{status} eq 'done' } @jobs),
            });
            await Future::IO->sleep(1);
        }
    };
};

$app;
