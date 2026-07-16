use v5.40;
use experimental 'signatures';
use PAGI::Nano;

# Ports PAGI's 08-tls-introspection to PAGI::Nano.
# A handler can read connection metadata the server puts on the scope: the
# scheme, client address, and — when the server terminates TLS — the TLS
# extension info (protocol version, cipher, client cert). No TLS -> tls is null.
#
#     pagi-server app.pl
#     curl http://127.0.0.1:5000/conninfo

my $app = app {
    get '/conninfo' => sub ($c) {
        my $tls = $c->scope->{extensions}{tls};
        {
            scheme => $c->scheme,
            client => $c->client,
            tls    => $tls
                ? { version => $tls->{version}, cipher => $tls->{cipher} }
                : undef,
        };
    };
};

$app;
