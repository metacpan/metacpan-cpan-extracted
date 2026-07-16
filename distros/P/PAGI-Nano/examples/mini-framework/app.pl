use v5.40;
use experimental 'signatures';
use Future::AsyncAwait;
use Future::IO;
use PAGI::Nano;

# Ports PAGI's "mini-framework" example to PAGI::Nano.
#
# That example hand-rolls a ~50-line micro-framework to prove a framework is just
# a thin layer over the PAGI protocol. PAGI::Nano *is* that idea, finished: the
# same routes (a greeting, a path parameter, an async handler) with nothing to
# hand-roll.
#
#     pagi-server app.pl

my $app = app {
    get '/' => sub ($c) { 'PAGI::Nano is the mini-framework, finished.' };

    get '/hello/:name' => sub ($c, $name) { "Hello, $name!" };

    get '/slow/:secs' => async sub ($c, $secs) {
        await Future::IO->sleep($secs);   # async handler; the loop stays free
        "waited ${secs}s";
    };
};

$app;
