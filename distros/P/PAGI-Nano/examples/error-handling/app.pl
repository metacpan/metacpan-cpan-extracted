use v5.40;
use experimental 'signatures';
use PAGI::Nano;

# The error model, all in one place. enable 'ErrorHandler' renders any uncaught
# exception as a tidy 500 (instead of the bare server default). For an error you
# *choose*, throw a respond-able: die $c->json(..., status => 4xx) and Nano
# sends it as-is — explicit, call-site-local, never a mystery die. not_found
# customizes the 404 for unmatched paths.
#
#     pagi-server app.pl
#     curl -i http://127.0.0.1:5000/ok        # 200
#     curl -i http://127.0.0.1:5000/teapot    # 418, chosen via die-a-respond-able
#     curl -i http://127.0.0.1:5000/boom      # 500, rendered by ErrorHandler
#     curl -i http://127.0.0.1:5000/nowhere   # 404, from not_found

my $app = app {
    enable 'ErrorHandler';      # uncaught exceptions -> a rendered 500

    get '/ok' => sub ($c) { { ok => 1 } };

    # An intentional, chosen error response: throw a respond-able value.
    get '/teapot' => sub ($c) {
        die $c->json({ error => "I'm a teapot", hint => 'chosen on purpose' }, status => 418);
    };

    # An unexpected failure: an ordinary die becomes a 500 (never a silent 200),
    # and ErrorHandler renders it.
    get '/boom' => sub ($c) { die "something broke deep in the stack\n" };

    not_found sub ($c) {
        $c->json({ error => 'no such route', path => $c->req->path }, status => 404);
    };
};

$app;
