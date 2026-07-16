use v5.40;
use experimental 'signatures';
use PAGI::Nano;

# Ports PAGI's 12-utf8 to PAGI::Nano.
# UTF-8 round-trips across the input vectors: the path segment (already decoded
# by PAGI) and the query string. Nano's JSON coercion encodes UTF-8 for you.
#
#     pagi-server app.pl
#     curl http://127.0.0.1:5000/echo/héllo
#     curl 'http://127.0.0.1:5000/echo/x?text=naïve'

my $app = app {
    get '/echo/:word' => sub ($c, $word) {
        {
            from_path  => $word,                          # decoded by PAGI
            from_query => $c->req->query_param('text'),   # decoded by Request
            length     => length($word),                  # characters, not bytes
        };
    };
};

$app;
