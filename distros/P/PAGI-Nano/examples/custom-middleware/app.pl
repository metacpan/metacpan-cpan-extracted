use v5.40;
use experimental 'signatures';
use FindBin ();
use lib "$FindBin::Bin/lib";
use PAGI::Nano;
use Example::Middleware::ApiKey;

# Write your own middleware and wire it two ways. A middleware is any object that
# subclasses PAGI::Middleware and implements wrap($app) (see ./lib/Example/
# Middleware/). They compose as an onion: app-wide outermost, route innermost.
#
#   - RequestTimer (app-wide): injects an X-Response-Time-Ms header on every
#     response by wrapping the send channel. enable resolves a bare name under
#     PAGI::Middleware::, so a leading ^ escapes the prefix for our own class.
#   - ApiKey (route-scoped): rejects requests without the right X-Api-Key with a
#     401 before the handler runs. It takes a configured key, so it is
#     pre-instantiated (route-scoped middleware take no constructor args).
#
#     pagi-server app.pl
#     curl -i http://127.0.0.1:5000/public                         # 200, X-Response-Time-Ms header
#     curl -i http://127.0.0.1:5000/private                        # 401
#     curl -i -H 'X-Api-Key: s3cr3t' http://127.0.0.1:5000/private # 200

my $app = app {
    enable '^Example::Middleware::RequestTimer';     # app-wide; ^ escapes the default prefix

    get '/public' => sub ($c) { { open => 1 } };

    get '/private' => [ Example::Middleware::ApiKey->new(key => 's3cr3t') ] => sub ($c) {
        { secret => 'the answer is 42' };
    };
};

$app;
