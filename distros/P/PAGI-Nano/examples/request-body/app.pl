use v5.40;
use experimental 'signatures';
use Future::AsyncAwait;
use PAGI::Nano;

# Ports PAGI's 03-request-body to PAGI::Nano.
# Read the whole request body and echo it back. PAGI::Request->body reads the
# http.request events for you, so the handler just awaits it.
#
#     pagi-server app.pl
#     curl -X POST --data 'hello' http://127.0.0.1:5000/echo

my $app = app {
    post '/echo' => async sub ($c) {
        my $body = await $c->req->body;
        $c->text($body, content_type => 'text/plain; charset=utf-8');
    };
};

$app;
