use v5.40;
use experimental 'signatures';
use PAGI::App::WrapPSGI;
use PAGI::Nano;

# Ports PAGI-Tools' 09-psgi-bridge to PAGI::Nano.
# A legacy synchronous PSGI app is wrapped by PAGI::App::WrapPSGI (which adapts it
# to the async PAGI interface) and mounted under a prefix — so old PSGI code runs
# alongside native Nano routes in the same app.
#
#     pagi-server app.pl
#     curl http://127.0.0.1:5000/legacy/anything

my $psgi_app = sub ($env) {
    my $body = "PSGI app saw: $env->{REQUEST_METHOD} $env->{PATH_INFO}";
    return [200, ['Content-Type' => 'text/plain'], [$body]];
};

my $app = app {
    get '/' => sub ($c) { 'Native Nano route; /legacy is a mounted PSGI app' };

    mount '/legacy' => PAGI::App::WrapPSGI->new(psgi_app => $psgi_app);
};

$app;
