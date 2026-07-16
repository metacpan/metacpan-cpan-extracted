use v5.40;
use experimental 'signatures';
use PAGI::Nano;

# Ports PAGI's 01-hello-http to PAGI::Nano.
# The minimal app: one route, a plain-text response.
#
#     pagi-server app.pl

my $app = app {
    get '/' => sub ($c) { 'Hello, PAGI::Nano!' };
};

$app;
