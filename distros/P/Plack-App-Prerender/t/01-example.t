#!perl

use strict;
use warnings;

use Test2::V0;
use Test2::Require::Internet;

use HTTP::Request::Common;
use HTTP::Status qw/ :constants /;
use HTTP::Tiny;
use Plack::Test;

use CHI;
use Log::Log4perl qw/ :easy /;

use Plack::App::Prerender;

Log::Log4perl->easy_init($ERROR);

my $cache = CHI->new( driver => 'Memory', global => 1 );

my $handler = Plack::App::Prerender->new(
    rewrite => 'https://httpbin.org',
    cache   => $cache,
    wait    => 5,
);

test_psgi
    app    => $handler->to_app,
    client => sub {

        my $cb  = shift;
        my $req = GET '/';
        my $res = $cb->($req);

        is $res->code, HTTP_OK, join( " ", $req->method, $req->uri );

        like $res->content, qr/react-text/, 'has dynamic text';

};

done_testing;
