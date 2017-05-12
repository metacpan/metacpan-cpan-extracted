use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Middleware::AutoRefresh;
use HTTP::Request::Common;

my $app = sub { [ 200, [ 'Content-Type' => 'text/html' ], ['<head></head>'] ] };

test_psgi app => Plack::Middleware::AutoRefresh->wrap($app), client => sub {
    my $cb = shift;

    my $req = GET 'http://localhost/';
    my $res = $cb->($req);

    like $res->content, qr/<head><script>/;
};

done_testing;
