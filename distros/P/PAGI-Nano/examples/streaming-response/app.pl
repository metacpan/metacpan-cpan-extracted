use v5.40;
use experimental 'signatures';
use Future::AsyncAwait;
use PAGI::Nano;

# Ports PAGI's 02-streaming-response to PAGI::Nano.
# Stream a chunked response body. $c->response->stream takes an async writer;
# returning the response lets Nano send it, nothing buffered. Register an
# on_disconnect callback to learn if the client goes away mid-stream (on a real
# server; in-process test clients have no live connection).
#
#     pagi-server app.pl
#     curl -N http://127.0.0.1:5000/stream

my $app = app {
    get '/stream' => sub ($c) {
        my $gone = 0;
        $c->on_disconnect(sub { $gone = 1 });

        $c->response->stream(async sub ($w) {
            for my $i (1 .. 5) {
                last if $gone;                 # stop early if the client left
                await $w->write("chunk $i\n");
            }
            await $w->close;
        });
    };
};

$app;
