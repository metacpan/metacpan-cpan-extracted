use v5.40;
use experimental 'signatures';
use Future::AsyncAwait;
use PAGI::Nano;

# Ports PAGI's 06-lifespan-state and PAGI-Tools' 14-lifespan-utils to PAGI::Nano.
# startup/shutdown manage app-lifetime shared state, which handlers read and
# mutate via $c->state.
#
#     pagi-server app.pl
#     curl http://127.0.0.1:5000/      # request count climbs across requests

my $app = app {
    startup async sub ($state) {
        $state->{requests} = 0;
        $state->{boot}     = 'started';
    };
    shutdown async sub ($state) {
        warn "served $state->{requests} requests\n";
    };

    get '/' => sub ($c) {
        $c->state->{requests}++;
        { boot => $c->state->{boot}, requests => $c->state->{requests} };
    };
};

$app;
