#!/usr/bin/env perl
#
# Explicit SSE close with PAGI::SSE->close(reason => ...)
#
# Streams a few "job progress" events, then ends the stream EXPLICITLY with
# sse.close instead of just returning. Demonstrates:
#
#   - close() from the handler with a SERVER-SIDE reason (logged to STDERR;
#     never sent to the client -- SSE has no close frame on the wire)
#   - a client-facing "done" sentinel event so the browser stops reconnecting
#   - on_close cleanup that runs however the stream ends (client gone OR close())
#
# Run:  pagi-server --app examples/sse-close/app.pl --port 5000
# Open: http://localhost:5000/
#
use strict;
use warnings;
use Future::AsyncAwait;
use Future::IO;
use Future::IO::Impl::IOAsync;   # loop-backed Future::IO->sleep under pagi-server

use PAGI::SSE;

my $PAGE = <<'HTML';
<!doctype html>
<meta charset="utf-8">
<title>PAGI SSE close demo</title>
<h1>Job progress</h1>
<pre id="log"></pre>
<script>
  const log = (m) => (document.getElementById('log').textContent += m + "\n");
  const es = new EventSource('/jobs');
  es.addEventListener('progress', (e) => log('progress ' + JSON.parse(e.data).pct + '%'));
  // The server cannot tell the browser "don't reconnect" on the wire, so we use
  // a sentinel event: on 'done', WE close -- which suppresses auto-reconnect.
  es.addEventListener('done', () => { log('done -- closing'); es.close(); });
  es.onerror = () => log('(connection error; would auto-reconnect unless closed)');
</script>
HTML

my $app = async sub {
    my ($scope, $receive, $send) = @_;
    my $type = $scope->{type} // '';

    # SSE stream: a few progress ticks, then an explicit close.
    if ($type eq 'sse') {
        my $sse = PAGI::SSE->new($scope, $receive, $send);

        # Runs once, however the stream ends (client disconnect OR our close()).
        # $reason is 'job_complete' on our close, or a disconnect reason if the
        # client leaves first. It is server-side only.
        $sse->on_close(async sub {
            my ($sse, $reason) = @_;
            print STDERR "SSE stream closed: reason=$reason\n";
        });

        await $sse->start;

        for my $pct (25, 50, 75, 100) {
            await $sse->send_event(event => 'progress', data => { pct => $pct });
            await Future::IO->sleep(0.5);
        }

        # Tell the CLIENT we are done (in-band sentinel it listens for), then end
        # the stream explicitly with a server-side reason. close() ends it now
        # and runs on_close before resolving.
        await $sse->send_event(event => 'done', data => { ok => 1 });
        await $sse->close(reason => 'job_complete');
        return;
    }

    # HTTP: serve the demo page.
    if ($type eq 'http') {
        await $send->({
            type    => 'http.response.start',
            status  => 200,
            headers => [ ['content-type', 'text/html; charset=utf-8'] ],
        });
        await $send->({ type => 'http.response.body', body => $PAGE });
        return;
    }

    die "Unsupported scope type: $type";
};

$app;
