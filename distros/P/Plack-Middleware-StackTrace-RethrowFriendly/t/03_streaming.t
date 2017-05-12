use strict;
use warnings;

# lib
use Plack::Middleware::StackTrace::RethrowFriendly;

# cpan
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

my $app = sub {
    eval { require DooBar };

    return sub {
        my $respond = shift;
        $respond->([ 200, [ "Content-Type", "text/plain" ], [ "Hello World" ] ]);
    };
};

$app = Plack::Middleware::StackTrace::RethrowFriendly->wrap($app);

test_psgi $app, sub {
    my $cb = shift;

    my $req = GET "/";
    my $res = $cb->($req);

    ok $res->is_success;
    like $res->content, qr/Hello World/;
};

done_testing;
