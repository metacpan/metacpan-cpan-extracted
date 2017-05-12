# vim: set expandtab ts=4 sw=4 nowrap ft=perl ff=unix :
use strict;
use warnings;
use Test::More;
use Plack::Middleware::BetterStackTrace;
use Plack::Test;
use HTTP::Request::Common;

my $app = sub {
    eval { require DooBar };

    return sub {
        my $respond = shift;
        $respond->([ 200, [ "Content-Type", "text/plain" ], ["Hello World"] ]);
    };
};

$app = Plack::Middleware::BetterStackTrace->wrap($app);

test_psgi $app, sub {
    my $cb = shift;

    my $req = GET "/";
    my $res = $cb->($req);

    ok $res->is_success;
    like $res->content, qr/Hello World/;
};

done_testing;
