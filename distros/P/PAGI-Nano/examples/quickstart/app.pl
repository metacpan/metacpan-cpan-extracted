use v5.40;
use experimental 'signatures';
use Future::AsyncAwait;   # handlers that use await must be `async sub`
use PAGI::Nano;

# Quickstart single-file app. Run it with:
#
#     pagi-server app.pl
#
# The file's last expression is the assembled PAGI app, which pagi-server runs.
# (If you add a ./lib, put it on @INC the standard way with
#  `use FindBin; use lib "$FindBin::Bin/lib";` — Nano never touches @INC.)

my $app = app {
    startup async sub ($state) { $state->{started} = 1 };

    enable 'GZip';

    get '/' => sub ($c) { 'Hello from PAGI::Nano' };

    get '/hello/:name' => sub ($c, $name) { { hello => $name } };

    post '/echo' => async sub ($c) {
        my $clean = await $c->params->permitted('message');
        $c->json($clean, status => 201);
    };
};

$app;
