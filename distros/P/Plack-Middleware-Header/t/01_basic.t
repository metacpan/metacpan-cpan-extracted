use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use Plack::Builder;
use Plack::Test;
use Cwd;

my $set_handler = builder {
    enable "Plack::Middleware::Header",
        set => ['X-Plack-One' => 'one']
    ;
    sub { ['200', ['Content-Type' => 'text/html'], ['hello world']] };
};

my $append_handler = builder {
    enable "Plack::Middleware::Header",
        append => ['X-Plack-One' => 'two']
    ;
    $set_handler;
};
my $unset_handler = builder {
    enable "Plack::Middleware::Header",
        unset => ['X-Plack-One']
    ;
    $append_handler;
};

test_psgi app => $set_handler, client => sub {
    my $cb = shift;

    {
        my $req = GET "http://localhost/";
        my $res = $cb->($req);
        is_deeply [$res->header('X-Plack-One')], ['one'];
    }
};

test_psgi app => $append_handler, client => sub {
    my $cb = shift;

    {
        my $req = GET "http://localhost/";
        my $res = $cb->($req);
        is_deeply [$res->header('X-Plack-One')], ['one', 'two'];
    }
};

test_psgi app => $unset_handler, client => sub {
    my $cb = shift;

    {
        my $req = GET "http://localhost/";
        my $res = $cb->($req);
        is_deeply [$res->header('X-Plack-One')], [];
    }
};



done_testing;
